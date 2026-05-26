import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Browser compass implementation using the `DeviceOrientationEvent` API.
///
/// On iOS Safari 13+ this requires a one-time permission request which
/// **must** be initiated from a user gesture (button tap). Calling
/// [requestPermission] from any other context returns false.
class WebCompass {
  static bool get isWeb => true;

  /// True on iOS browsers, where `DeviceOrientationEvent.requestPermission`
  /// must be called from a user gesture before any orientation events fire.
  static bool get needsPermissionPrompt {
    try {
      final eventClass =
          globalContext.getProperty<JSObject?>('DeviceOrientationEvent'.toJS);
      if (eventClass == null) return false;
      return eventClass.has('requestPermission');
    } catch (_) {
      return false;
    }
  }

  /// Returns true if permission was granted (or wasn't required).
  /// Must be called from within a user-gesture handler on iOS.
  static Future<bool> requestPermission() async {
    if (!needsPermissionPrompt) return true;
    try {
      final eventClass =
          globalContext.getProperty<JSObject>('DeviceOrientationEvent'.toJS);
      final promise = eventClass.callMethod<JSPromise<JSString>>(
        'requestPermission'.toJS,
      );
      final result = (await promise.toDart).toDart;
      return result == 'granted';
    } catch (_) {
      return false;
    }
  }

  /// Stream of compass headings in degrees, normalized to [0, 360).
  /// Uses `webkitCompassHeading` (iOS — already true north) when available,
  /// otherwise the absolute Z-axis rotation (`alpha`) from
  /// `deviceorientationabsolute` events (Android Chrome).
  static Stream<double> headings() {
    late StreamController<double> controller;
    late JSFunction handlerJs;

    void handler(web.Event event) {
      final jsEvent = event as JSObject;

      // iOS: webkitCompassHeading is already corrected to true north.
      final wkRaw = jsEvent.getProperty<JSAny?>('webkitCompassHeading'.toJS);
      if (wkRaw != null) {
        final h = (wkRaw as JSNumber).toDartDouble;
        if (!h.isNaN) {
          controller.add(_normalize(h));
          return;
        }
      }

      // Android Chrome `deviceorientationabsolute`: in modern Chrome (and
      // most Chromium-derived browsers, which is the vast majority of
      // Android web users) `alpha` is the compass heading directly —
      // degrees CLOCKWISE from north — NOT W3C-spec CCW. The previous
      // `360 - alpha` was correct only for spec-compliant browsers
      // (Firefox) and inverted the heading on every Chrome user, causing
      // Qibla errors that scale with how far the user faces from north.
      final alphaRaw = jsEvent.getProperty<JSAny?>('alpha'.toJS);
      if (alphaRaw != null) {
        final alpha = (alphaRaw as JSNumber).toDartDouble;
        if (!alpha.isNaN) {
          controller.add(_normalize(alpha));
        }
      }
    }

    controller = StreamController<double>.broadcast(
      onListen: () {
        handlerJs = handler.toJS;
        web.window.addEventListener('deviceorientationabsolute', handlerJs);
        web.window.addEventListener('deviceorientation', handlerJs);
      },
      onCancel: () {
        web.window.removeEventListener('deviceorientationabsolute', handlerJs);
        web.window.removeEventListener('deviceorientation', handlerJs);
      },
    );
    return controller.stream;
  }

  static double _normalize(double deg) {
    var d = deg % 360;
    if (d < 0) d += 360;
    return d;
  }
}
