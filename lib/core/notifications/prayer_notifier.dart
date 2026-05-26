import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Schedules and cancels local prayer-time notifications.
///
/// iOS caps pending notifications at ~64; we schedule the next 7 days
/// (5 prayers × 7 = 35 entries, well within the cap) and re-schedule
/// when the app is resumed or daily at midnight.
class PrayerNotifier {
  static const _androidChannelId = 'prayer_times';
  static const _androidChannelName = 'Prayer times';
  static const _androidChannelDescription = 'Athan notifications for the five daily prayers.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _timezoneName;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    _timezoneName = await FlutterTimezone.getLocalTimezone();
    if (_timezoneName != null) {
      tz.setLocalLocation(tz.getLocation(_timezoneName!));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
      ));
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
    _initialized = true;
  }

  /// Schedules athan notifications for the given prayer-times list.
  /// [items] is a list of (prayer, when, label) entries — typically built by
  /// iterating today + the next 6 days and pulling fajr..isha from each.
  Future<void> reschedule({
    required List<PendingPrayer> items,
    int preReminderMinutes = 0,
  }) async {
    await init();
    await _plugin.cancelAll();

    int notifId = 0;
    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    for (final item in items) {
      if (item.when.isBefore(DateTime.now())) continue;

      // Main athan notification at prayer time.
      await _plugin.zonedSchedule(
        notifId++,
        item.title,
        item.subtitle,
        tz.TZDateTime.from(item.when, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'prayer:${item.prayer.name}:${item.when.toIso8601String()}',
      );

      // Optional pre-reminder.
      if (preReminderMinutes > 0) {
        final reminderTime =
            item.when.subtract(Duration(minutes: preReminderMinutes));
        if (reminderTime.isAfter(DateTime.now())) {
          await _plugin.zonedSchedule(
            notifId++,
            '${item.title} in $preReminderMinutes min',
            item.subtitle,
            tz.TZDateTime.from(reminderTime, tz.local),
            details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Fires an immediate notification (no schedule). Used for the "Test
  /// notification" button so the user can verify OS-level permissions
  /// without waiting for the next prayer.
  Future<void> sendTestNow() async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(
      999999, // arbitrary id outside the scheduled range
      'Salatuk test notification',
      'Notifications are working. Athan will fire at each prayer time.',
      details,
    );
  }
}

class PendingPrayer {
  final adhan.Prayer prayer;
  final DateTime when;
  final String title;
  final String subtitle;
  const PendingPrayer({
    required this.prayer,
    required this.when,
    required this.title,
    required this.subtitle,
  });
}
