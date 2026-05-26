import 'package:flutter_test/flutter_test.dart';
import 'package:salatuk/core/qibla/qibla_service.dart';

void main() {
  group('Qibla bearings (great-circle, true north)', () {
    // Expected values are the library's own great-circle bearing from each
    // city to the Kaaba (21.4225241°N, 39.8261818°E). The library — adhan_dart
    // 2.0.1, a verified port of Batoul Apps Adhan — is the source of truth
    // per RESEARCH.md §2.3. These pinned values guard against any regression
    // in the math: if the library's output drifts more than 0.5°, this test
    // fails loudly so we can verify the change is intentional.
    //
    // Cross-checked against islamicfinder.org and qiblafinder.withgoogle.com
    // — differences from those sources are typically <2° due to slightly
    // different Kaaba coordinates in publish references.
    final cases = <String, ({double lat, double lng, double expected})>{
      'London, UK': (lat: 51.5074, lng: -0.1278, expected: 118.99),
      'New York City, USA': (lat: 40.7128, lng: -74.0060, expected: 58.48),
      'Toronto, Canada': (lat: 43.6532, lng: -79.3832, expected: 54.58),
      'Jakarta, Indonesia': (lat: -6.2088, lng: 106.8456, expected: 295.15),
      'Sydney, Australia': (lat: -33.8688, lng: 151.2093, expected: 277.50),
      'Istanbul, Türkiye': (lat: 41.0082, lng: 28.9784, expected: 151.62),
      'Karachi, Pakistan': (lat: 24.8607, lng: 67.0011, expected: 267.74),
      'Cairo, Egypt': (lat: 30.0444, lng: 31.2357, expected: 136.14),
      'Kuala Lumpur, Malaysia': (lat: 3.1390, lng: 101.6869, expected: 292.54),
      // Cape Town: RESEARCH.md §5.1.4 — great-circle is 23.35°, not the
      // rhumb-line 20.24° some sites publish.
      'Cape Town, South Africa': (lat: -33.9249, lng: 18.4241, expected: 23.35),
      'Beirut, Lebanon': (lat: 33.8938, lng: 35.5018, expected: 161.88),
      'Dubai, UAE': (lat: 25.2048, lng: 55.2708, expected: 258.23),
      'Riyadh, Saudi Arabia': (lat: 24.7136, lng: 46.6753, expected: 243.80),
      'Tokyo, Japan': (lat: 35.6762, lng: 139.6503, expected: 293.00),
      'Lagos, Nigeria': (lat: 6.5244, lng: 3.3792, expected: 63.33),
      'Moscow, Russia': (lat: 55.7558, lng: 37.6173, expected: 176.36),
      'Singapore': (lat: 1.3521, lng: 103.8198, expected: 293.02),
    };

    cases.forEach((name, c) {
      test(name, () {
        final b = QiblaService.bearingFromTrueNorth(
          latitude: c.lat,
          longitude: c.lng,
        );
        // Compare modulo 360 to handle e.g. 359.9 vs 0.1.
        final diff = ((b - c.expected + 540) % 360) - 180;
        // 0.5° tolerance: pinned to library output; catches drift.
        expect(diff.abs(), lessThan(0.5),
            reason:
                'Computed $b°, expected ${c.expected}° (diff ${diff.toStringAsFixed(3)}°)');
      });
    });

    test('bearing is in [0, 360)', () {
      final b = QiblaService.bearingFromTrueNorth(latitude: 0, longitude: 0);
      expect(b, greaterThanOrEqualTo(0));
      expect(b, lessThan(360));
    });

    test('observer at Kaaba returns finite value (no NaN)', () {
      final b = QiblaService.bearingFromTrueNorth(
          latitude: 21.4225241, longitude: 39.8261818);
      expect(b.isFinite, isTrue);
    });

    test('south of Kaaba on same longitude → bearing ≈ 0° (true north)', () {
      // Observer directly south of Kaaba: Qibla is due north.
      final b = QiblaService.bearingFromTrueNorth(
          latitude: 0.0, longitude: 39.8261818);
      // Should be very close to 0° (or 360°).
      final norm = b > 180 ? b - 360 : b;
      expect(norm.abs(), lessThan(0.5));
    });

    test('north of Kaaba on same longitude → bearing ≈ 180° (true south)', () {
      // Observer at 60°N, same longitude: Qibla is due south.
      final b = QiblaService.bearingFromTrueNorth(
          latitude: 60.0, longitude: 39.8261818);
      expect((b - 180.0).abs(), lessThan(0.5));
    });

    test('east of Kaaba on equator → bearing in WNW quadrant (270°-300°)', () {
      // Observer 60° east of Kaaba on equator: Qibla bearing tilts slightly
      // north of due-west because Kaaba sits at 21.4°N.
      final b = QiblaService.bearingFromTrueNorth(
          latitude: 0.0, longitude: 99.8261818);
      expect(b, greaterThan(270));
      expect(b, lessThan(310));
    });
  });
}
