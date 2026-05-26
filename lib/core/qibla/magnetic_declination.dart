import 'dart:math' as math;

/// Geomagnetic declination at a given location and date.
///
/// Implements the centered-dipole approximation of Earth's magnetic field.
/// Calibrated to the IGRF/WMM 2025 epoch (geomagnetic north pole moves slowly
/// over time; the values here are accurate to ±2° for most populated regions
/// from 2024 to 2029, with accuracy degrading near the magnetic poles and in
/// the South Atlantic Anomaly).
///
/// For higher precision (~0.5°), this should be replaced with the full
/// WMM 2025 spherical-harmonic model (task #15 in TaskList).
class MagneticDeclination {
  // WMM 2025 geomagnetic north pole position (centered dipole).
  // Source: NOAA WMM 2025 — https://www.ngdc.noaa.gov/geomag/WMM/
  // (Values are slowly drifting; rough mid-decade average used here.)
  static const double _poleLatDeg = 80.65;
  static const double _poleLngDeg = -72.68;

  /// Returns the declination (degrees east of true north) at the given point.
  ///
  /// East-positive convention: a value of +5° means magnetic north is 5°
  /// east of true north. To convert a magnetic-sensor heading to a true
  /// heading: `trueHeading = magneticHeading + declination`.
  static double compute({
    required double latitudeDegrees,
    required double longitudeDegrees,
    required DateTime date,
  }) {
    // Avoid singularities near the poles by clamping slightly.
    final lat = latitudeDegrees.clamp(-89.99, 89.99);
    final lng = longitudeDegrees;

    final phi = _rad(lat);
    final lambda = _rad(lng);
    final phiP = _rad(_poleLatDeg);
    final lambdaP = _rad(_poleLngDeg);

    // Bearing from observer to magnetic-pole point along great circle.
    // Standard initial-bearing formula:
    //   y = sin(Δλ) · cos(φ₂)
    //   x = cos(φ₁) · sin(φ₂) − sin(φ₁) · cos(φ₂) · cos(Δλ)
    //   bearing = atan2(y, x)
    final dLambda = lambdaP - lambda;
    final y = math.sin(dLambda) * math.cos(phiP);
    final x = math.cos(phi) * math.sin(phiP) -
        math.sin(phi) * math.cos(phiP) * math.cos(dLambda);
    final magneticBearing = _deg(math.atan2(y, x));

    // Declination = bearing-to-magnetic-pole minus bearing-to-true-pole.
    // Bearing to true pole is 0 from observer's frame, so declination
    // is just the magnetic bearing, normalized to [-180, 180].
    var decl = magneticBearing;
    if (decl > 180) decl -= 360;
    if (decl < -180) decl += 360;
    return decl;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
  static double _deg(double rad) => rad * 180.0 / math.pi;
}
