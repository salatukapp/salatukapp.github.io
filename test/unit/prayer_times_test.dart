import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_test/flutter_test.dart';
import 'package:salatuk/core/prayer_times/prayer_times_service.dart';
import 'package:salatuk/core/prayer_times/sunni_method.dart';

void main() {
  group('PrayerTimesService', () {
    final service = PrayerTimesService();

    test('Riyadh: returns ordered prayers and reasonable values', () {
      final times = service.computeFor(
        latitude: 24.7136,
        longitude: 46.6753,
        date: DateTime.utc(2026, 5, 26),
        method: SunniMethod.ummAlQura,
        madhab: adhan.Madhab.shafi,
      );
      expect(times.fajr.isBefore(times.sunrise), isTrue);
      expect(times.sunrise.isBefore(times.dhuhr), isTrue);
      expect(times.dhuhr.isBefore(times.asr), isTrue);
      expect(times.asr.isBefore(times.maghrib), isTrue);
      expect(times.maghrib.isBefore(times.isha), isTrue);
    });

    test('Beirut on a known summer day: prayers fall in expected hour ranges', () {
      // Sanity check against published values for Beirut, 2026-06-21 (summer solstice).
      // Egyptian method; only checking gross order-of-magnitude correctness so the
      // test stays robust to small algorithmic changes.
      final times = service.computeFor(
        latitude: 33.8938,
        longitude: 35.5018,
        date: DateTime.utc(2026, 6, 21),
        method: SunniMethod.egyptian,
        madhab: adhan.Madhab.shafi,
      );
      // Local time is UTC+3 in summer; convert.
      final local = times.fajr.toUtc().add(const Duration(hours: 3));
      expect(local.hour, inInclusiveRange(2, 4),
          reason: 'Fajr local hour: ${local.hour}');

      final dhuhrLocal = times.dhuhr.toUtc().add(const Duration(hours: 3));
      expect(dhuhrLocal.hour, inInclusiveRange(11, 13));
    });

    test('Hanafi Asr is later than Shafi Asr (same date+location)', () {
      const lat = 33.8938;
      const lng = 35.5018;
      final date = DateTime.utc(2026, 5, 26);
      final shafi = service.computeFor(
        latitude: lat,
        longitude: lng,
        date: date,
        method: SunniMethod.muslimWorldLeague,
        madhab: adhan.Madhab.shafi,
      );
      final hanafi = service.computeFor(
        latitude: lat,
        longitude: lng,
        date: date,
        method: SunniMethod.muslimWorldLeague,
        madhab: adhan.Madhab.hanafi,
      );
      expect(hanafi.asr.isAfter(shafi.asr), isTrue,
          reason: 'Hanafi Asr should be later');
    });

    test('Different methods give different Fajr times in same place', () {
      const lat = 33.8938;
      const lng = 35.5018;
      final date = DateTime.utc(2026, 5, 26);
      final mwl = service.computeFor(
        latitude: lat,
        longitude: lng,
        date: date,
        method: SunniMethod.muslimWorldLeague,
        madhab: adhan.Madhab.shafi,
      );
      final isna = service.computeFor(
        latitude: lat,
        longitude: lng,
        date: date,
        method: SunniMethod.northAmerica,
        madhab: adhan.Madhab.shafi,
      );
      // ISNA uses a shallower 15° angle than MWL's 18°, so ISNA Fajr is later.
      expect(isna.fajr.isAfter(mwl.fajr), isTrue);
    });

    test('User offsets shift the prayer time', () {
      const lat = 33.8938;
      const lng = 35.5018;
      final date = DateTime.utc(2026, 5, 26);
      final base = service.computeFor(
        latitude: lat,
        longitude: lng,
        date: date,
        method: SunniMethod.muslimWorldLeague,
        madhab: adhan.Madhab.shafi,
      );
      final offset = service.computeFor(
        latitude: lat,
        longitude: lng,
        date: date,
        method: SunniMethod.muslimWorldLeague,
        madhab: adhan.Madhab.shafi,
        userOffsetsMinutes: {adhan.Prayer.fajr: 5},
      );
      expect(offset.fajr.difference(base.fajr).inMinutes, equals(5));
    });
  });
}
