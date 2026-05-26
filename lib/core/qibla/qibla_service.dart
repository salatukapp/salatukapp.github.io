import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_compass_v2/flutter_compass_v2.dart';

import 'magnetic_declination.dart';

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
  /// Uses adhan_dart's spherical-trigonometry formula. Always great-circle.
  static double bearingFromTrueNorth({
    required double latitude,
    required double longitude,
  }) {
    return adhan.Qibla.qibla(adhan.Coordinates(latitude, longitude));
  }

  /// Live stream of [QiblaReading]. Applies WMM magnetic-declination correction
  /// to convert sensor's magnetic heading to true heading.
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
    if (events == null) {
      return const Stream.empty();
    }
    return events.map((CompassEvent event) {
      final magneticHeading = event.heading ?? 0;
      final trueHeading = _normalize(magneticHeading + declination);
      double delta = qibla - trueHeading;
      delta = ((delta + 540) % 360) - 180;
      return QiblaReading(
        qiblaTrueBearing: qibla,
        trueHeading: trueHeading,
        deltaToQibla: delta,
        declinationUsed: declination,
        sensorAccuracy: event.accuracy,
      );
    });
  }

  static double _normalize(double deg) {
    var d = deg % 360;
    if (d < 0) d += 360;
    return d;
  }
}
