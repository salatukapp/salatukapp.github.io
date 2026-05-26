/// No-op stub used on Android/iOS native — those platforms use
/// [package:flutter_compass_v2] directly via [QiblaService.compassStream].
class WebCompass {
  static bool get isWeb => false;
  static bool get needsPermissionPrompt => false;
  static Future<bool> requestPermission() async => true;
  static Stream<double> headings() => const Stream<double>.empty();
}
