import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../location/location_service.dart';
import '../prayer_times/prayer_times_service.dart';
import '../storage/settings_store.dart';
import 'prayer_notifier.dart';

/// Single entry point used by any screen to (re)schedule athan notifications
/// from the current persisted settings + location.
///
/// On web this is largely a no-op — browsers don't reliably fire scheduled
/// background notifications, so we skip the work.
class NotificationScheduler {
  /// Re-schedule the next ~7 days of prayer notifications based on the
  /// currently saved settings. Cancels everything if the user has disabled
  /// notifications. Returns the number of notifications scheduled (or 0).
  static Future<int> reschedule() async {
    if (kIsWeb) return 0;

    final store = SettingsStore();
    final settings = await store.load();
    final notifier = PrayerNotifier();

    if (!settings.notificationsEnabled) {
      await notifier.cancelAll();
      return 0;
    }

    // Need a location. Prefer the saved manual override; otherwise try a
    // single (foreground) GPS fix. If neither is available, give up — the
    // user can re-enable from Prayer Times screen once they pick a city.
    double? lat = settings.manualLatitude;
    double? lng = settings.manualLongitude;
    if (lat == null || lng == null) {
      try {
        final pos = await LocationService().getCurrent();
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        return 0;
      }
    }

    final service = PrayerTimesService();
    final items = <PendingPrayer>[];
    final now = DateTime.now();
    // iOS hard-caps pending notifications at 64. Each day adds 5 (fajr/
    // dhuhr/asr/maghrib/isha); pre-reminders double that. Cap to 6 days
    // when pre-reminders are on so we stay under the iOS limit.
    final dayCount = settings.preNotificationMinutes > 0 ? 6 : 7;

    for (var i = 0; i < dayCount; i++) {
      final day = now.add(Duration(days: i));
      final t = service.computeFor(
        latitude: lat,
        longitude: lng,
        date: day,
        method: settings.method,
        madhab: settings.madhab,
      );
      void add(adhan.Prayer p, DateTime when, String name) {
        if (when.isAfter(now)) {
          items.add(PendingPrayer(
            prayer: p,
            when: when,
            title: '$name prayer',
            subtitle: 'It is time to pray $name',
          ));
        }
      }

      add(adhan.Prayer.fajr, t.fajr.toLocal(), 'Fajr');
      add(adhan.Prayer.dhuhr, t.dhuhr.toLocal(), 'Dhuhr');
      add(adhan.Prayer.asr, t.asr.toLocal(), 'Asr');
      add(adhan.Prayer.maghrib, t.maghrib.toLocal(), 'Maghrib');
      add(adhan.Prayer.isha, t.isha.toLocal(), 'Isha');
    }

    try {
      await notifier.reschedule(
        items: items,
        preReminderMinutes: settings.preNotificationMinutes,
      );
      return items.length;
    } catch (_) {
      return 0;
    }
  }

  /// Fires an immediate "Salatuk notifications are working" notification so
  /// the user can verify their OS permissions are correct without waiting
  /// for the next prayer.
  static Future<bool> sendTestNotification() async {
    if (kIsWeb) return false;
    try {
      await PrayerNotifier().sendTestNow();
      return true;
    } catch (_) {
      return false;
    }
  }
}
