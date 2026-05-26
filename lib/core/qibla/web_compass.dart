// Conditional re-export: on non-web platforms returns a no-op stub; on web
// pulls in the DeviceOrientationEvent-based implementation.
export 'web_compass_stub.dart'
    if (dart.library.js_interop) 'web_compass_web.dart';
