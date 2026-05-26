import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:hijri/hijri_calendar.dart';

import 'sunni_method.dart';

class PrayerTimesService {
  /// Computes prayer times for the given date and location.
  ///
  /// [date] is interpreted as a local date — only year/month/day are used;
  /// times are calculated in UTC internally and returned as UTC DateTimes.
  /// Convert to local time at the display layer.
  ///
  /// [umAlQuraRamadanAdjustment] when true and method is Umm al-Qura adds
  /// the canonical +30 min to Isha during Ramadan (see RESEARCH.md §1.6).
  adhan.PrayerTimes computeFor({
    required double latitude,
    required double longitude,
    required DateTime date,
    required SunniMethod method,
    required adhan.Madhab madhab,
    adhan.HighLatitudeRule? highLatitudeRule,
    Map<adhan.Prayer, int> userOffsetsMinutes = const {},
    bool umAlQuraRamadanAdjustment = true,
  }) {
    final params = method.toAdhanParameters();
    params.madhab = madhab;
    if (highLatitudeRule != null) {
      params.highLatitudeRule = highLatitudeRule;
    }

    // Layer user offsets on top of method's built-in adjustments.
    if (userOffsetsMinutes.isNotEmpty) {
      final base = Map<adhan.Prayer, int>.from(params.adjustments);
      userOffsetsMinutes.forEach((prayer, mins) {
        base[prayer] = (base[prayer] ?? 0) + mins;
      });
      params.adjustments = base;
    }

    // Umm al-Qura: +30 min for Isha during Ramadan (canonical Saudi practice).
    if (umAlQuraRamadanAdjustment && method == SunniMethod.ummAlQura) {
      final hijri = HijriCalendar.fromDate(date);
      if (hijri.hMonth == 9) {
        final adj = Map<adhan.Prayer, int>.from(params.adjustments);
        adj[adhan.Prayer.isha] = (adj[adhan.Prayer.isha] ?? 0) + 30;
        params.adjustments = adj;
      }
    }

    return adhan.PrayerTimes(
      coordinates: adhan.Coordinates(latitude, longitude),
      date: DateTime.utc(date.year, date.month, date.day),
      calculationParameters: params,
    );
  }

  /// Prayer times for today and tomorrow's Fajr — used for "next prayer" UX
  /// after Isha (when the next prayer is tomorrow's Fajr).
  ({adhan.PrayerTimes today, DateTime tomorrowFajr}) computeForToday({
    required double latitude,
    required double longitude,
    required SunniMethod method,
    required adhan.Madhab madhab,
    adhan.HighLatitudeRule? highLatitudeRule,
    Map<adhan.Prayer, int> userOffsetsMinutes = const {},
  }) {
    final now = DateTime.now();
    final today = computeFor(
      latitude: latitude,
      longitude: longitude,
      date: now,
      method: method,
      madhab: madhab,
      highLatitudeRule: highLatitudeRule,
      userOffsetsMinutes: userOffsetsMinutes,
    );
    return (today: today, tomorrowFajr: today.fajrAfter);
  }
}

/// Light wrapper around adhan_dart's [adhan.Prayer] enum with display labels.
extension PrayerLabel on adhan.Prayer {
  String get label {
    switch (this) {
      case adhan.Prayer.fajr:
      case adhan.Prayer.fajrAfter:
        return 'Fajr';
      case adhan.Prayer.sunrise:
        return 'Sunrise';
      case adhan.Prayer.dhuhr:
        return 'Dhuhr';
      case adhan.Prayer.asr:
        return 'Asr';
      case adhan.Prayer.maghrib:
        return 'Maghrib';
      case adhan.Prayer.isha:
      case adhan.Prayer.ishaBefore:
        return 'Isha';
    }
  }

  String get labelArabic {
    switch (this) {
      case adhan.Prayer.fajr:
      case adhan.Prayer.fajrAfter:
        return 'الفجر';
      case adhan.Prayer.sunrise:
        return 'الشروق';
      case adhan.Prayer.dhuhr:
        return 'الظهر';
      case adhan.Prayer.asr:
        return 'العصر';
      case adhan.Prayer.maghrib:
        return 'المغرب';
      case adhan.Prayer.isha:
      case adhan.Prayer.ishaBefore:
        return 'العشاء';
    }
  }
}
