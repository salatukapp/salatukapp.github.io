import 'package:flutter_test/flutter_test.dart';
import 'package:salatuk/core/qibla/compass_math.dart';

void main() {
  group('CompassMath.headingFromAlpha (W3C alpha → compass heading)', () {
    // W3C DeviceOrientation alpha is CCW from north; heading is CW from north.
    // Canonical mapping that guards against the alpha-inversion regression:
    //   alpha 0 → 0 (N), 90 → 270 (W), 180 → 180 (S), 270 → 90 (E).
    test('alpha 0 → 0° (North)', () {
      expect(CompassMath.headingFromAlpha(0), closeTo(0, 0.001));
    });
    test('alpha 90 → 270° (West)', () {
      expect(CompassMath.headingFromAlpha(90), closeTo(270, 0.001));
    });
    test('alpha 180 → 180° (South)', () {
      expect(CompassMath.headingFromAlpha(180), closeTo(180, 0.001));
    });
    test('alpha 270 → 90° (East)', () {
      expect(CompassMath.headingFromAlpha(270), closeTo(90, 0.001));
    });

    test('landscape screen angle is subtracted', () {
      // Device rotated 90° (landscape): a raw alpha of 0 should report 270.
      expect(CompassMath.headingFromAlpha(0, screenAngle: 90), closeTo(270, 0.001));
      // alpha 90 with 90° screen → 180.
      expect(CompassMath.headingFromAlpha(90, screenAngle: 90), closeTo(180, 0.001));
    });

    test('output always in [0, 360)', () {
      for (var a = 0.0; a < 360; a += 7) {
        for (final s in [0.0, 90.0, 180.0, 270.0]) {
          final h = CompassMath.headingFromAlpha(a, screenAngle: s);
          expect(h, greaterThanOrEqualTo(0));
          expect(h, lessThan(360));
        }
      }
    });
  });

  group('CompassMath.normalize', () {
    test('wraps negative', () => expect(CompassMath.normalize(-90), closeTo(270, 0.001)));
    test('wraps over 360', () => expect(CompassMath.normalize(450), closeTo(90, 0.001)));
    test('keeps in-range', () => expect(CompassMath.normalize(123), closeTo(123, 0.001)));
  });
}
