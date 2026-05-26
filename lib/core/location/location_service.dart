import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool fromCache;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.fromCache,
  });
}

class LocationException implements Exception {
  final String message;
  final LocationFailure kind;
  const LocationException(this.kind, this.message);
  @override
  String toString() => 'LocationException($kind): $message';
}

enum LocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationService {
  /// Requests permission (if needed) and returns the current position.
  /// Throws [LocationException] on any failure.
  Future<LocationResult> getCurrent({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      throw const LocationException(
        LocationFailure.servicesDisabled,
        'Location services are disabled on this device. Enable them in system settings.',
      );
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      // Browser prompts that get dismissed (rather than answered) can hang
      // forever, so wrap the request in our own external timeout too.
      try {
        perm = await Geolocator.requestPermission().timeout(timeout);
      } on TimeoutException {
        throw const LocationException(
          LocationFailure.timeout,
          'No response to the location permission prompt. Try again, or enter a city manually in settings.',
        );
      }
      if (perm == LocationPermission.denied) {
        throw const LocationException(
          LocationFailure.permissionDenied,
          'Location permission denied. Grant it to get accurate prayer times automatically, or enter a city manually in settings.',
        );
      }
    }

    if (perm == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationFailure.permissionDeniedForever,
        'Location permission is permanently denied. Open app settings and grant it, or enter a city manually.',
      );
    }

    try {
      // Belt-and-braces: the platform's own `timeLimit` is not honored by
      // every implementation (especially geolocator_web on desktops with no
      // GPS where the browser stalls). Add an external `.timeout()` so the
      // UI always escapes.
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: timeout,
      ).timeout(timeout);
      return LocationResult(
        latitude: pos.latitude,
        longitude: pos.longitude,
        timestamp: DateTime.now(),
        fromCache: false,
      );
    } on TimeoutException {
      throw const LocationException(
        LocationFailure.timeout,
        'Location request timed out. On a desktop without GPS, enter a city manually in settings.',
      );
    } on Exception catch (e) {
      throw LocationException(LocationFailure.unknown, e.toString());
    }
  }
}
