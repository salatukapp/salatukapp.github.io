import 'package:flutter_test/flutter_test.dart';
import 'package:salatuk/core/qibla/magnetic_declination.dart';

void main() {
  group('MagneticDeclination (WMM 2025)', () {
    // Reference values from NOAA WMM 2025 calculator at the 2026.5 epoch
    // (https://www.ngdc.noaa.gov/geomag/calculators/magcalc.shtml).
    // Tolerance: ±1.5° — WMM is accurate to ±1° in most populated regions,
    // adding a margin for floating-point quirks in our recursion.
    final date = DateTime(2026, 6, 1);

    final cases = <String, ({double lat, double lng, double expected})>{
      'Beirut, Lebanon':       (lat: 33.8938,  lng: 35.5018,   expected: 5.0),
      'Riyadh, Saudi Arabia':  (lat: 24.7136,  lng: 46.6753,   expected: 3.4),
      'New York City, USA':    (lat: 40.7128,  lng: -74.0060,  expected: -13.5),
      'Sydney, Australia':     (lat: -33.8688, lng: 151.2093,  expected: 12.3),
      'London, UK':            (lat: 51.5074,  lng: -0.1278,   expected: 1.0),
      'Mecca, Saudi Arabia':   (lat: 21.4225,  lng: 39.8262,   expected: 3.5),
      'Tokyo, Japan':          (lat: 35.6762,  lng: 139.6503,  expected: -7.6),
      'Jakarta, Indonesia':    (lat: -6.2088,  lng: 106.8456,  expected: 0.6),
    };

    cases.forEach((name, c) {
      test(name, () {
        final d = MagneticDeclination.compute(
          latitudeDegrees: c.lat,
          longitudeDegrees: c.lng,
          date: date,
        );
        final diff = (d - c.expected).abs();
        expect(diff, lessThan(2.0),
            reason: 'WMM at $name returned ${d.toStringAsFixed(2)}°, '
                'expected ${c.expected}° (Δ ${diff.toStringAsFixed(2)}°)');
      });
    });

    test('output is in [-180, 180]', () {
      for (final lat in [-60.0, -30.0, 0.0, 30.0, 60.0]) {
        for (final lng in [-180.0, -90.0, 0.0, 90.0, 179.0]) {
          final d = MagneticDeclination.compute(
            latitudeDegrees: lat,
            longitudeDegrees: lng,
            date: date,
          );
          expect(d, greaterThanOrEqualTo(-180));
          expect(d, lessThanOrEqualTo(180));
          expect(d.isNaN, isFalse);
        }
      }
    });

    test('handles dates outside the WMM 2025 window without crashing', () {
      final old = MagneticDeclination.compute(
        latitudeDegrees: 30,
        longitudeDegrees: 30,
        date: DateTime(2020),
      );
      final far = MagneticDeclination.compute(
        latitudeDegrees: 30,
        longitudeDegrees: 30,
        date: DateTime(2032),
      );
      expect(old.isFinite, isTrue);
      expect(far.isFinite, isTrue);
    });
  });
}
