import '../prayer_times/sunni_method.dart';

/// Returns the recommended Sunni calculation method for a given location.
///
/// Uses coarse rectangular regions; the user can always override in settings.
/// Choices are based on the established conventions documented in
/// `RESEARCH.md` section 1.6 (Regional defaults).
class RegionDetector {
  static SunniMethod recommendedMethod({
    required double latitude,
    required double longitude,
  }) {
    final lat = latitude;
    final lng = longitude;

    // Saudi Arabia + most of the GCC
    if (_inBox(lat, lng, latMin: 16, latMax: 33, lngMin: 34, lngMax: 56)) {
      return SunniMethod.ummAlQura;
    }

    // Türkiye (Diyanet)
    if (_inBox(lat, lng, latMin: 35, latMax: 43, lngMin: 25, lngMax: 45)) {
      return SunniMethod.turkiye;
    }

    // Egypt + Sudan + Libya + Levant
    if (_inBox(lat, lng, latMin: 15, latMax: 37, lngMin: 24, lngMax: 39)) {
      return SunniMethod.egyptian;
    }

    // Morocco
    if (_inBox(lat, lng, latMin: 27, latMax: 36, lngMin: -13, lngMax: -1)) {
      return SunniMethod.morocco;
    }

    // Algeria
    if (_inBox(lat, lng, latMin: 18, latMax: 38, lngMin: -9, lngMax: 12)) {
      return SunniMethod.algerian;
    }

    // Tunisia
    if (_inBox(lat, lng, latMin: 30, latMax: 38, lngMin: 7, lngMax: 12)) {
      return SunniMethod.tunisia;
    }

    // Pakistan, India, Bangladesh, Afghanistan, Sri Lanka
    if (_inBox(lat, lng, latMin: 5, latMax: 38, lngMin: 60, lngMax: 95)) {
      return SunniMethod.karachi;
    }

    // Singapore + immediate surroundings (check before Indonesia, which
    // has a box that overlaps Singapore's coordinates).
    if (_inBox(lat, lng, latMin: 1, latMax: 6, lngMin: 100, lngMax: 105)) {
      return SunniMethod.singapore;
    }

    // Indonesia, Malaysia
    if (_inBox(lat, lng, latMin: -11, latMax: 7, lngMin: 95, lngMax: 141)) {
      return SunniMethod.indonesian;
    }

    // North America (Canada, US, Mexico down to ~14°N)
    if (_inBox(lat, lng, latMin: 14, latMax: 84, lngMin: -170, lngMax: -52)) {
      return SunniMethod.northAmerica;
    }

    // UK + Ireland — Moonsighting Committee preferred at higher latitudes
    if (_inBox(lat, lng, latMin: 49, latMax: 61, lngMin: -11, lngMax: 2)) {
      return SunniMethod.moonsightingCommittee;
    }

    // Russia
    if (_inBox(lat, lng, latMin: 41, latMax: 82, lngMin: 19, lngMax: 180)) {
      return SunniMethod.russia;
    }

    // Above 55° N — high-latitude friendly default
    if (lat >= 55) {
      return SunniMethod.moonsightingCommittee;
    }

    // Continental Europe
    if (_inBox(lat, lng, latMin: 35, latMax: 60, lngMin: -10, lngMax: 30)) {
      return SunniMethod.muslimWorldLeague;
    }

    // Fallback
    return SunniMethod.muslimWorldLeague;
  }

  static bool _inBox(
    double lat,
    double lng, {
    required double latMin,
    required double latMax,
    required double lngMin,
    required double lngMax,
  }) {
    return lat >= latMin && lat <= latMax && lng >= lngMin && lng <= lngMax;
  }
}
