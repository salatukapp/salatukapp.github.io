/// Pure, platform-independent compass-heading helpers, factored out of the
/// web JS-interop layer so the angle conversion can be unit-tested without a
/// browser (see test/unit/compass_math_test.dart).
class CompassMath {
  /// Converts a W3C `DeviceOrientationEvent.alpha` into a compass heading.
  ///
  /// Per the W3C Device Orientation spec, `alpha` is the rotation about the
  /// z-axis measured **counter-clockwise**, with `alpha == 0` when the top of
  /// the device points to (true, for absolute events) north:
  ///   alpha 0 → North, 90 → West, 180 → South, 270 → East.
  /// A compass heading is the opposite sense (clockwise from north), so:
  ///   heading = 360 − alpha.
  ///
  /// [screenAngle] (0/90/180/270, from `screen.orientation.angle`) compensates
  /// for the device being held in landscape — `alpha` is referenced to the
  /// device's natural orientation, not the current screen rotation.
  static double headingFromAlpha(double alpha, {double screenAngle = 0}) {
    return normalize(360.0 - alpha - screenAngle);
  }

  /// Normalizes any degree value into the [0, 360) range.
  static double normalize(double deg) {
    var d = deg % 360.0;
    if (d < 0) d += 360.0;
    return d;
  }
}
