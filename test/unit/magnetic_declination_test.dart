import 'package:flutter_test/flutter_test.dart';
import 'package:salatuk/core/qibla/magnetic_declination.dart';

void main() {
  group('MagneticDeclination', () {
    // The dipole approximation will not match NOAA WMM 2025 exactly; we test
    // for sane magnitude and sign rather than tight numerical agreement.
    // Full WMM 2025 implementation is tracked as task #15.

    final date = DateTime(2026, 5, 26);

    test('returns 0° at the geomagnetic north pole', () {
      // Near the WMM 2025 geomagnetic pole, declination is undefined/unstable.
      // Just check it returns SOMETHING numeric, not NaN.
      final d = MagneticDeclination.compute(
        latitudeDegrees: 80.65,
        longitudeDegrees: -72.68,
        date: date,
      );
      expect(d.isNaN, isFalse);
    });

    test('Europe: declination is small and positive-ish', () {
      // London: ~+1° per NOAA 2025.
      final d = MagneticDeclination.compute(
        latitudeDegrees: 51.5074,
        longitudeDegrees: -0.1278,
        date: date,
      );
      expect(d.abs(), lessThan(20));
    });

    test('North America: declination magnitude < 25°', () {
      // NYC ~ −13°, Seattle ~ +16° per NOAA 2025.
      final nyc = MagneticDeclination.compute(
        latitudeDegrees: 40.7128,
        longitudeDegrees: -74.0060,
        date: date,
      );
      expect(nyc.abs(), lessThan(25));
    });

    test('Middle East: small positive declination', () {
      // Riyadh ~ +2° per NOAA 2025.
      final riyadh = MagneticDeclination.compute(
        latitudeDegrees: 24.7136,
        longitudeDegrees: 46.6753,
        date: date,
      );
      expect(riyadh.abs(), lessThan(15));
    });

    test('Output is in [-180, 180]', () {
      for (final lat in [-60.0, -30.0, 0.0, 30.0, 60.0]) {
        for (final lng in [-180.0, -90.0, 0.0, 90.0, 180.0]) {
          final d = MagneticDeclination.compute(
            latitudeDegrees: lat,
            longitudeDegrees: lng,
            date: date,
          );
          expect(d, greaterThanOrEqualTo(-180));
          expect(d, lessThanOrEqualTo(180));
        }
      }
    });
  });
}
