import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_compass_v2/flutter_compass_v2.dart';

import 'magnetic_declination.dart';
import 'web_compass.dart';

class QiblaReading {
  /// Target Qibla bearing from true north, degrees clockwise.
  final double qiblaTrueBearing;

  /// Current device heading from true north, after declination correction.
  final double trueHeading;

  /// Signed shortest delta to Qibla, in degrees in [-180, 180].
  /// Zero when facing Qibla; positive = rotate clockwise, negative = ccw.
  final double deltaToQibla;

  /// Sensor accuracy if available (radians on Android, degrees on iOS).
  final double? sensorAccuracy;

  /// Magnetic declination used to convert sensor to true heading, in degrees.
  final double declinationUsed;

  const QiblaReading({
    required this.qiblaTrueBearing,
    required this.trueHeading,
    required this.deltaToQibla,
    required this.declinationUsed,
    this.sensorAccuracy,
  });

  bool get isFacingQibla => deltaToQibla.abs() < 3.0;
  bool get isNearQibla => deltaToQibla.abs() < 10.0;
}

class QiblaService {
  /// Pure-math Qibla bearing from true north (degrees clockwise) to the Kaaba.
  static double bearingFromTrueNorth({
    required double latitude,
    required double longitude,
  }) {
    return adhan.Qibla.qibla(adhan.Coordinates(latitude, longitude));
  }

  /// Native-platform live compass stream. Applies WMM 2025 declination
  /// correction on Android (where the sensor returns magnetic heading) but
  /// not on iOS (where flutter_compass_v2 internally calls
  /// `CLHeading.trueHeading` which is already true-north corrected).
  Stream<QiblaReading> compassStream({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    final qibla = bearingFromTrueNorth(latitude: latitude, longitude: longitude);
    final declination = MagneticDeclination.compute(
      latitudeDegrees: latitude,
      longitudeDegrees: longitude,
      date: date,
    );
    final events = FlutterCompass.events;
    if (events == null) return const Stream.empty();
    // iOS path: flutter_compass_v2 already returns trueHeading; do NOT add
    // declination (verified in plugin's SwiftFlutterCompassPlugin.swift).
    // Android path: raw magnetic azimuth — apply WMM declination.
    final iosNative = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final declToApply = iosNative ? 0.0 : declination;
    return events
        // Filter out invalid readings. `event.heading` is null when the
        // sensor hasn't produced a reading yet; on iOS it's negative when
        // CLHeading.trueHeading is unavailable (location services off, etc).
        // Treating either as 0 would peg the needle to "facing north" no
        // matter where the phone actually points — a major Qibla error.
        .where((e) => e.heading != null && e.heading! >= 0 && !e.heading!.isNaN)
        .map((CompassEvent event) {
      final rawHeading = event.heading!;
      final trueHeading = _normalize(rawHeading + declToApply);
      double delta = qibla - trueHeading;
      delta = ((delta + 540) % 360) - 180;
      return QiblaReading(
        qiblaTrueBearing: qibla,
        trueHeading: trueHeading,
        deltaToQibla: delta,
        declinationUsed: declToApply,
        sensorAccuracy: event.accuracy,
      );
    });
  }

  /// Browser compass stream. On iOS this requires the caller to have already
  /// invoked [WebCompass.requestPermission] from a user-gesture handler;
  /// otherwise no events will fire.
  ///
  /// On iOS the underlying `webkitCompassHeading` is already corrected to
  /// true north — we skip declination math. On Android Chrome the `alpha`
  /// is magnetic heading, so we apply WMM declination.
  Stream<QiblaReading> webCompassStream({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    final qibla = bearingFromTrueNorth(latitude: latitude, longitude: longitude);
    final declination = MagneticDeclination.compute(
      latitudeDegrees: latitude,
      longitudeDegrees: longitude,
      date: date,
    );
    // On iOS browsers, webkitCompassHeading is true heading already.
    final bool iosLike = WebCompass.needsPermissionPrompt;
    return WebCompass.headings().map((rawHeading) {
      final trueHeading = iosLike
          ? _normalize(rawHeading)
          : _normalize(rawHeading + declination);
      double delta = qibla - trueHeading;
      delta = ((delta + 540) % 360) - 180;
      return QiblaReading(
        qiblaTrueBearing: qibla,
        trueHeading: trueHeading,
        deltaToQibla: delta,
        declinationUsed: iosLike ? 0 : declination,
      );
    });
  }

  /// True if the current platform's compass needs an explicit user-gesture
  /// permission prompt (iOS Safari).
  bool get needsWebPermission => kIsWeb && WebCompass.needsPermissionPrompt;

  /// True for any web platform — caller should use [webCompassStream].
  bool get isWeb => kIsWeb;

  static double _normalize(double deg) {
    var d = deg % 360;
    if (d < 0) d += 360;
    return d;
  }
}
