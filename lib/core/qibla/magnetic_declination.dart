import 'dart:math' as math;

/// Geomagnetic declination from the **World Magnetic Model 2025** (NOAA / BGS,
/// valid 2025.0–2030.0). Ported from the public-domain NOAA reference
/// algorithm via `pygeomag` (boxpet/pygeomag, MIT-licensed).
///
/// Accuracy: declination RMS error 0.26° + 5417/H global; **±0.5° in most
/// populated regions, ±1° in caution zones, undefined within 2000 nT of the
/// magnetic poles** (which the NOAA model itself doesn't claim to handle).
///
/// Coefficients live in [_gnm], [_hnm], [_dgnm], [_dhnm] — copied verbatim
/// from `wmm2025_coefficients.txt` (alongside this file) which is the
/// official NOAA WMM2025.COF.
class MagneticDeclination {
  /// WMM 2025 is valid through the start of 2030. After that the coefficients
  /// should be refreshed from the successor model. Output still degrades
  /// gracefully past this date; this is a maintenance signal, not a hard stop.
  static bool isExpired(DateTime date) => date.year >= 2030;

  static const int _n = 12;
  static const int _size = _n + 1;

  // WGS-84 constants
  static const double _a = 6378.137;
  static const double _b = 6356.7523142;
  static const double _re = 6371.2;

  /// Returns geomagnetic declination at the given point (degrees east of true
  /// north). Sea-level assumed unless [altitudeKm] is given. Year is derived
  /// from [date].
  ///
  /// East-positive: a value of +5° means magnetic north is 5° east of true
  /// north. To convert magnetic-sensor heading to true:
  /// `trueHeading = magneticHeading + declination`.
  static double compute({
    required double latitudeDegrees,
    required double longitudeDegrees,
    required DateTime date,
    double altitudeKm = 0,
  }) {
    final lat = latitudeDegrees.clamp(-89.999, 89.999);
    final glon = longitudeDegrees;

    final yearStart = DateTime(date.year);
    final daysInYear = DateTime(date.year + 1).difference(yearStart).inDays;
    final time = date.year + date.difference(yearStart).inDays / daysInYear;

    final result = _calculate(glat: lat, glon: glon, alt: altitudeKm, time: time);
    return result;
  }

  // ---------------------------------------------------------------------------
  // The NOAA reference algorithm uses a clever single-matrix trick:
  //  - Upper triangle c[m][n] stores g_n^m
  //  - Lower triangle c[n][m-1] stores h_n^{m}
  // We replicate that exactly so the algorithm is line-for-line traceable to
  // the published C / Python sources.
  // ---------------------------------------------------------------------------

  static List<List<double>> _zeroes2D() =>
      List.generate(_size, (_) => List<double>.filled(_size, 0));

  static List<double> _zeroes1D() => List<double>.filled(_size * _size, 0);

  static double _calculate({
    required double glat,
    required double glon,
    required double alt,
    required double time,
  }) {
    final c = _zeroes2D();
    final cd = _zeroes2D();
    final tc = _zeroes2D();
    final dp = _zeroes2D();
    final snorm = _zeroes1D();
    final sp = List<double>.filled(_size, 0);
    final cp = List<double>.filled(_size, 0);
    final pp = List<double>.filled(_size, 0);
    final fn = List<double>.filled(_size, 0);
    final fm = List<double>.filled(_size, 0);
    final k = _zeroes2D();

    sp[0] = 0;
    cp[0] = pp[0] = 1;
    dp[0][0] = 0;

    // Load coefficients g[m][n] (upper triangle) and h[n][m-1] (lower triangle).
    c[0][0] = 0;
    cd[0][0] = 0;
    for (final row in _coeffs) {
      final n = row[0].toInt();
      final m = row[1].toInt();
      if (m > _n) break;
      if (m > n || m < 0) {
        throw StateError('Corrupt WMM coefficient row');
      }
      c[m][n] = row[2];
      cd[m][n] = row[4];
      if (m != 0) {
        c[n][m - 1] = row[3];
        cd[n][m - 1] = row[5];
      }
    }

    // Convert Schmidt normalized to unnormalized Gauss coefficients.
    snorm[0] = 1;
    fm[0] = 0;
    for (var nn = 1; nn <= _n; nn++) {
      snorm[nn] = snorm[nn - 1] * (2 * nn - 1) / nn;
      var j = 2;
      var m = 0;
      const d1 = 1;
      var d2 = (nn - m + d1) ~/ d1;
      while (d2 > 0) {
        k[m][nn] = (((nn - 1) * (nn - 1)) - (m * m)) /
            ((2 * nn - 1) * (2 * nn - 3)).toDouble();
        if (m > 0) {
          final flnmj = (nn - m + 1) * j / (nn + m).toDouble();
          snorm[nn + m * _size] =
              snorm[nn + (m - 1) * _size] * math.sqrt(flnmj);
          j = 1;
          c[nn][m - 1] = snorm[nn + m * _size] * c[nn][m - 1];
          cd[nn][m - 1] = snorm[nn + m * _size] * cd[nn][m - 1];
        }
        c[m][nn] = snorm[nn + m * _size] * c[m][nn];
        cd[m][nn] = snorm[nn + m * _size] * cd[m][nn];
        d2 -= 1;
        m += d1;
      }
      fn[nn] = (nn + 1).toDouble();
      fm[nn] = nn.toDouble();
    }
    k[1][1] = 0;

    // WMM 2025 is valid 2025.0–2030.0. Past that, the linear secular-variation
    // extrapolation degrades gracefully (still far better than freezing the
    // field), so we don't throw — callers can check [isExpired] to prompt a
    // coefficient refresh from the successor NOAA .COF.
    final dt = time - 2025.0; // WMM 2025 epoch
    final rlon = glon * math.pi / 180.0;
    final rlat = glat * math.pi / 180.0;
    final srlon = math.sin(rlon);
    final srlat = math.sin(rlat);
    final crlon = math.cos(rlon);
    final crlat = math.cos(rlat);
    final srlat2 = srlat * srlat;
    final crlat2 = crlat * crlat;
    sp[1] = srlon;
    cp[1] = crlon;

    // Geodetic to spherical
    final a2 = _a * _a;
    final b2 = _b * _b;
    final c2 = a2 - b2;
    final a4 = a2 * a2;
    final b4 = b2 * b2;
    final c4 = a4 - b4;

    final q = math.sqrt(a2 - c2 * srlat2);
    final q1 = alt * q;
    final q2 = ((q1 + a2) / (q1 + b2)) * ((q1 + a2) / (q1 + b2));
    final ct = srlat / math.sqrt(q2 * crlat2 + srlat2);
    final st = math.sqrt(1.0 - ct * ct);
    final r2 = alt * alt + 2.0 * q1 + (a4 - c4 * srlat2) / (q * q);
    final r = math.sqrt(r2);
    final d = math.sqrt(a2 * crlat2 + b2 * srlat2);
    final ca = (alt + d) / r;
    final sa = c2 * crlat * srlat / (r * d);

    for (var m = 2; m <= _n; m++) {
      sp[m] = sp[1] * cp[m - 1] + cp[1] * sp[m - 1];
      cp[m] = cp[1] * cp[m - 1] - sp[1] * sp[m - 1];
    }

    final aor = _re / r;
    var ar = aor * aor;
    var br = 0.0;
    var bt = 0.0;
    var bp = 0.0;
    var bpp = 0.0;

    for (var nn = 1; nn <= _n; nn++) {
      ar = ar * aor;
      var m = 0;
      const d3 = 1;
      var d4 = (nn + m + d3) ~/ d3;
      while (d4 > 0) {
        // Legendre + derivative recursion
        if (nn == m) {
          snorm[nn + m * _size] = st * snorm[nn - 1 + (m - 1) * _size];
          dp[m][nn] =
              st * dp[m - 1][nn - 1] + ct * snorm[nn - 1 + (m - 1) * _size];
        } else if (nn == 1 && m == 0) {
          snorm[nn + m * _size] = ct * snorm[nn - 1 + m * _size];
          dp[m][nn] = ct * dp[m][nn - 1] - st * snorm[nn - 1 + m * _size];
        } else if (nn > 1 && nn != m) {
          if (m > nn - 2) snorm[nn - 2 + m * _size] = 0.0;
          if (m > nn - 2) dp[m][nn - 2] = 0.0;
          snorm[nn + m * _size] = ct * snorm[nn - 1 + m * _size] -
              k[m][nn] * snorm[nn - 2 + m * _size];
          dp[m][nn] = ct * dp[m][nn - 1] -
              st * snorm[nn - 1 + m * _size] -
              k[m][nn] * dp[m][nn - 2];
        }

        // Time-adjust
        tc[m][nn] = c[m][nn] + dt * cd[m][nn];
        if (m != 0) {
          tc[nn][m - 1] = c[nn][m - 1] + dt * cd[nn][m - 1];
        }

        // Accumulate spherical-harmonic terms
        final par = ar * snorm[nn + m * _size];
        double temp1, temp2;
        if (m == 0) {
          temp1 = tc[m][nn] * cp[m];
          temp2 = tc[m][nn] * sp[m];
        } else {
          temp1 = tc[m][nn] * cp[m] + tc[nn][m - 1] * sp[m];
          temp2 = tc[m][nn] * sp[m] - tc[nn][m - 1] * cp[m];
        }
        bt = bt - ar * temp1 * dp[m][nn];
        bp += fm[m] * temp2 * par;
        br += fn[nn] * temp1 * par;

        // Polar special case
        if (st == 0.0 && m == 1) {
          if (nn == 1) {
            pp[nn] = pp[nn - 1];
          } else {
            pp[nn] = ct * pp[nn - 1] - k[m][nn] * pp[nn - 2];
          }
          final parp = ar * pp[nn];
          bpp += fm[m] * temp2 * parp;
        }

        d4 -= 1;
        m += d3;
      }
    }

    if (st == 0) {
      bp = bpp;
    } else {
      bp /= st;
    }

    // Rotate to geodetic frame
    final bx = -bt * ca - br * sa;
    final by = bp;
    // bz is not needed for declination — keep for completeness if expanded later.

    return math.atan2(by, bx) * 180.0 / math.pi;
  }

  /// WMM 2025 coefficients verbatim from the NOAA `.COF` file.
  /// Each row: [n, m, g, h, dg/dt, dh/dt]
  static const List<List<double>> _coeffs = [
    [1, 0, -29351.8, 0.0, 12.0, 0.0],
    [1, 1, -1410.8, 4545.4, 9.7, -21.5],
    [2, 0, -2556.6, 0.0, -11.6, 0.0],
    [2, 1, 2951.1, -3133.6, -5.2, -27.7],
    [2, 2, 1649.3, -815.1, -8.0, -12.1],
    [3, 0, 1361.0, 0.0, -1.3, 0.0],
    [3, 1, -2404.1, -56.6, -4.2, 4.0],
    [3, 2, 1243.8, 237.5, 0.4, -0.3],
    [3, 3, 453.6, -549.5, -15.6, -4.1],
    [4, 0, 895.0, 0.0, -1.6, 0.0],
    [4, 1, 799.5, 278.6, -2.4, -1.1],
    [4, 2, 55.7, -133.9, -6.0, 4.1],
    [4, 3, -281.1, 212.0, 5.6, 1.6],
    [4, 4, 12.1, -375.6, -7.0, -4.4],
    [5, 0, -233.2, 0.0, 0.6, 0.0],
    [5, 1, 368.9, 45.4, 1.4, -0.5],
    [5, 2, 187.2, 220.2, 0.0, 2.2],
    [5, 3, -138.7, -122.9, 0.6, 0.4],
    [5, 4, -142.0, 43.0, 2.2, 1.7],
    [5, 5, 20.9, 106.1, 0.9, 1.9],
    [6, 0, 64.4, 0.0, -0.2, 0.0],
    [6, 1, 63.8, -18.4, -0.4, 0.3],
    [6, 2, 76.9, 16.8, 0.9, -1.6],
    [6, 3, -115.7, 48.8, 1.2, -0.4],
    [6, 4, -40.9, -59.8, -0.9, 0.9],
    [6, 5, 14.9, 10.9, 0.3, 0.7],
    [6, 6, -60.7, 72.7, 0.9, 0.9],
    [7, 0, 79.5, 0.0, -0.0, 0.0],
    [7, 1, -77.0, -48.9, -0.1, 0.6],
    [7, 2, -8.8, -14.4, -0.1, 0.5],
    [7, 3, 59.3, -1.0, 0.5, -0.8],
    [7, 4, 15.8, 23.4, -0.1, 0.0],
    [7, 5, 2.5, -7.4, -0.8, -1.0],
    [7, 6, -11.1, -25.1, -0.8, 0.6],
    [7, 7, 14.2, -2.3, 0.8, -0.2],
    [8, 0, 23.2, 0.0, -0.1, 0.0],
    [8, 1, 10.8, 7.1, 0.2, -0.2],
    [8, 2, -17.5, -12.6, 0.0, 0.5],
    [8, 3, 2.0, 11.4, 0.5, -0.4],
    [8, 4, -21.7, -9.7, -0.1, 0.4],
    [8, 5, 16.9, 12.7, 0.3, -0.5],
    [8, 6, 15.0, 0.7, 0.2, -0.6],
    [8, 7, -16.8, -5.2, -0.0, 0.3],
    [8, 8, 0.9, 3.9, 0.2, 0.2],
    [9, 0, 4.6, 0.0, -0.0, 0.0],
    [9, 1, 7.8, -24.8, -0.1, -0.3],
    [9, 2, 3.0, 12.2, 0.1, 0.3],
    [9, 3, -0.2, 8.3, 0.3, -0.3],
    [9, 4, -2.5, -3.3, -0.3, 0.3],
    [9, 5, -13.1, -5.2, 0.0, 0.2],
    [9, 6, 2.4, 7.2, 0.3, -0.1],
    [9, 7, 8.6, -0.6, -0.1, -0.2],
    [9, 8, -8.7, 0.8, 0.1, 0.4],
    [9, 9, -12.9, 10.0, -0.1, 0.1],
    [10, 0, -1.3, 0.0, 0.1, 0.0],
    [10, 1, -6.4, 3.3, 0.0, 0.0],
    [10, 2, 0.2, 0.0, 0.1, -0.0],
    [10, 3, 2.0, 2.4, 0.1, -0.2],
    [10, 4, -1.0, 5.3, -0.0, 0.1],
    [10, 5, -0.6, -9.1, -0.3, -0.1],
    [10, 6, -0.9, 0.4, 0.0, 0.1],
    [10, 7, 1.5, -4.2, -0.1, 0.0],
    [10, 8, 0.9, -3.8, -0.1, -0.1],
    [10, 9, -2.7, 0.9, -0.0, 0.2],
    [10, 10, -3.9, -9.1, -0.0, -0.0],
    [11, 0, 2.9, 0.0, 0.0, 0.0],
    [11, 1, -1.5, 0.0, -0.0, -0.0],
    [11, 2, -2.5, 2.9, 0.0, 0.1],
    [11, 3, 2.4, -0.6, 0.0, -0.0],
    [11, 4, -0.6, 0.2, 0.0, 0.1],
    [11, 5, -0.1, 0.5, -0.1, -0.0],
    [11, 6, -0.6, -0.3, 0.0, -0.0],
    [11, 7, -0.1, -1.2, -0.0, 0.1],
    [11, 8, 1.1, -1.7, -0.1, -0.0],
    [11, 9, -1.0, -2.9, -0.1, 0.0],
    [11, 10, -0.2, -1.8, -0.1, 0.0],
    [11, 11, 2.6, -2.3, -0.1, 0.0],
    [12, 0, -2.0, 0.0, 0.0, 0.0],
    [12, 1, -0.2, -1.3, 0.0, -0.0],
    [12, 2, 0.3, 0.7, -0.0, 0.0],
    [12, 3, 1.2, 1.0, -0.0, -0.1],
    [12, 4, -1.3, -1.4, -0.0, 0.1],
    [12, 5, 0.6, -0.0, -0.0, -0.0],
    [12, 6, 0.6, 0.6, 0.1, -0.0],
    [12, 7, 0.5, -0.1, -0.0, -0.0],
    [12, 8, -0.1, 0.8, 0.0, 0.0],
    [12, 9, -0.4, 0.1, 0.0, -0.0],
    [12, 10, -0.2, -1.0, -0.1, -0.0],
    [12, 11, -1.3, 0.1, -0.0, 0.0],
    [12, 12, -0.7, 0.2, -0.1, -0.1],
  ];
}
