import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'compass_math.dart';

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

  /// Stream of true-north compass headings in degrees [0, 360).
  ///
  /// Two paths:
  /// - **iOS Safari**: `webkitCompassHeading` is already a true-north heading
  ///   (clockwise from north). Emit it directly.
  /// - **Android Chrome / others**: use `alpha` ONLY from an *absolute*
  ///   orientation event (`event.absolute == true`). The spec's `alpha` is
  ///   counter-clockwise, so the heading is `360 − alpha`. Relative
  ///   `deviceorientation` frames (absolute == false) have an arbitrary zero
  ///   and are dropped — emitting them would make the needle jump between two
  ///   reference frames and point the wrong way.
  ///
  /// We intentionally do NOT compensate for `screen.orientation.angle`: doing
  /// so caused the heading to jump 90° the moment a phone auto-rotated (the
  /// angle flips 0→90). A Qibla compass is held upright in portrait, so we
  /// assume the natural orientation and tell the user to hold the phone flat
  /// and upright. The exact great-circle bearing (the number) is always shown
  /// regardless and never moves.
  static Stream<double> headings() {
    late StreamController<double> controller;
    late JSFunction handlerJs;

    void handler(web.Event event) {
      final jsEvent = event as JSObject;

      // iOS path: webkitCompassHeading is true-north corrected by the OS.
      final wkRaw = jsEvent.getProperty<JSAny?>('webkitCompassHeading'.toJS);
      if (wkRaw != null) {
        final h = (wkRaw as JSNumber).toDartDouble;
        if (!h.isNaN && h >= 0) {
          controller.add(CompassMath.normalize(h));
          return;
        }
      }

      // Non-iOS path: only trust ABSOLUTE orientation events. A relative
      // event's alpha is referenced to wherever the sensor happened to start,
      // not to north — using it would yield a confidently-wrong Qibla.
      final absRaw = jsEvent.getProperty<JSAny?>('absolute'.toJS);
      final isAbsolute = absRaw != null && (absRaw as JSBoolean).toDart;
      if (!isAbsolute) return;

      final alphaRaw = jsEvent.getProperty<JSAny?>('alpha'.toJS);
      if (alphaRaw != null) {
        final alpha = (alphaRaw as JSNumber).toDartDouble;
        if (!alpha.isNaN) {
          controller.add(CompassMath.headingFromAlpha(alpha));
        }
      }
    }

    controller = StreamController<double>.broadcast(
      onListen: () {
        handlerJs = handler.toJS;
        // 'deviceorientationabsolute' is the Chromium absolute event; plain
        // 'deviceorientation' is also registered because (a) iOS delivers
        // webkitCompassHeading on it, and (b) a few browsers set
        // absolute==true on the plain event. The absolute gate above ensures
        // only true-north frames are ever emitted regardless of event name.
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
}
