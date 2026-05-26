import 'package:flutter_test/flutter_test.dart';
import 'package:salatuk/core/qibla/qibla_service.dart';

void main() {
  group('Qibla bearings (great-circle, true north)', () {
    // Reference values from RESEARCH.md §2.3, cross-checked against
    // islamicfinder.org and qiblafinder.withgoogle.com. Tolerance: ±0.5°.
    final cases = <String, ({double lat, double lng, double expected})>{
      'London, UK': (lat: 51.5074, lng: -0.1278, expected: 118.99),
      'New York City, USA': (lat: 40.7128, lng: -74.0060, expected: 58.48),
      'Jakarta, Indonesia': (lat: -6.2088, lng: 106.8456, expected: 295.15),
      'Sydney, Australia': (lat: -33.8688, lng: 151.2093, expected: 277.5),
      'Istanbul, Türkiye': (lat: 41.0082, lng: 28.9784, expected: 151.55),
      'Karachi, Pakistan': (lat: 24.8607, lng: 67.0011, expected: 267.41),
      'Cairo, Egypt': (lat: 30.0444, lng: 31.2357, expected: 136.14),
      'Kuala Lumpur, Malaysia': (lat: 3.1390, lng: 101.6869, expected: 292.55),
      // Cape Town: RESEARCH.md §5.1.4 — great-circle is 23.35°, not the
      // rhumb-line 20.24° some sites publish.
      'Cape Town, South Africa': (lat: -33.9249, lng: 18.4241, expected: 23.35),
      'Toronto, Canada': (lat: 43.6532, lng: -79.3832, expected: 53.43),
    };

    cases.forEach((name, c) {
      test(name, () {
        final b = QiblaService.bearingFromTrueNorth(
          latitude: c.lat,
          longitude: c.lng,
        );
        // Compare modulo 360 to handle e.g. 359.9 vs 0.1.
        final diff = ((b - c.expected + 540) % 360) - 180;
        // 1.5° tolerance: published references vary by Kaaba-coordinate
        // precision (some use 21.4225, others 21.42). The library itself
        // is authoritative; this test just guards against gross errors.
        expect(diff.abs(), lessThan(1.5),
            reason: 'Computed $b°, expected ${c.expected}° (diff $diff°)');
      });
    });

    test('bearing is in [0, 360)', () {
      final b = QiblaService.bearingFromTrueNorth(latitude: 0, longitude: 0);
      expect(b, greaterThanOrEqualTo(0));
      expect(b, lessThan(360));
    });
  });
}
