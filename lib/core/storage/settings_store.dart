import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:shared_preferences/shared_preferences.dart';

import '../prayer_times/sunni_method.dart';

/// Persisted user settings. All values are stored locally on-device.
class Settings {
  final SunniMethod method;
  final adhan.Madhab madhab;
  final bool notificationsEnabled;
  final int preNotificationMinutes;
  final String languageCode;
  final ThemePreference theme;
  final double? manualLatitude;
  final double? manualLongitude;
  final String? manualCityLabel;
  final bool autoDetectMethod;

  /// True once the user has opted into GPS on the first-run screen. Stored
  /// separately from manualLatitude (which is a FROZEN override that disables
  /// live GPS) so the first-run chooser isn't shown again on every cold start.
  final bool gpsChosen;

  const Settings({
    this.method = SunniMethod.karachi,
    this.madhab = adhan.Madhab.shafi,
    this.notificationsEnabled = true,
    this.preNotificationMinutes = 0,
    this.languageCode = 'en',
    this.theme = ThemePreference.system,
    this.manualLatitude,
    this.manualLongitude,
    this.manualCityLabel,
    this.autoDetectMethod = true,
    this.gpsChosen = false,
  });

  Settings copyWith({
    SunniMethod? method,
    adhan.Madhab? madhab,
    bool? notificationsEnabled,
    int? preNotificationMinutes,
    String? languageCode,
    ThemePreference? theme,
    double? manualLatitude,
    double? manualLongitude,
    String? manualCityLabel,
    bool? autoDetectMethod,
    bool? gpsChosen,
    bool clearManualLocation = false,
  }) {
    return Settings(
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preNotificationMinutes:
          preNotificationMinutes ?? this.preNotificationMinutes,
      languageCode: languageCode ?? this.languageCode,
      theme: theme ?? this.theme,
      manualLatitude:
          clearManualLocation ? null : (manualLatitude ?? this.manualLatitude),
      manualLongitude: clearManualLocation
          ? null
          : (manualLongitude ?? this.manualLongitude),
      manualCityLabel: clearManualLocation
          ? null
          : (manualCityLabel ?? this.manualCityLabel),
      autoDetectMethod: autoDetectMethod ?? this.autoDetectMethod,
      gpsChosen: gpsChosen ?? this.gpsChosen,
    );
  }
}

enum ThemePreference { system, light, dark }

class SettingsStore {
  static const _kMethod = 'method.code';
  static const _kMadhab = 'madhab';
  static const _kNotifEnabled = 'notif.enabled';
  static const _kPreNotifMin = 'notif.preMinutes';
  static const _kLang = 'lang';
  static const _kTheme = 'theme';
  static const _kManLat = 'loc.manLat';
  static const _kManLng = 'loc.manLng';
  static const _kManCity = 'loc.manCity';
  static const _kAutoDetect = 'method.auto';
  static const _kGpsChosen = 'loc.gpsChosen';

  Future<Settings> load() async {
    final p = await SharedPreferences.getInstance();
    return Settings(
      method: SunniMethod.fromCode(
          p.getString(_kMethod) ?? SunniMethod.karachi.code),
      madhab: (p.getString(_kMadhab) ?? 'shafi') == 'hanafi'
          ? adhan.Madhab.hanafi
          : adhan.Madhab.shafi,
      notificationsEnabled: p.getBool(_kNotifEnabled) ?? true,
      preNotificationMinutes: p.getInt(_kPreNotifMin) ?? 0,
      languageCode: p.getString(_kLang) ?? 'en',
      theme: _decodeTheme(p.getString(_kTheme)),
      manualLatitude: p.getDouble(_kManLat),
      manualLongitude: p.getDouble(_kManLng),
      manualCityLabel: p.getString(_kManCity),
      autoDetectMethod: p.getBool(_kAutoDetect) ?? true,
      gpsChosen: p.getBool(_kGpsChosen) ?? false,
    );
  }

  Future<void> save(Settings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMethod, s.method.code);
    await p.setString(_kMadhab, s.madhab == adhan.Madhab.hanafi ? 'hanafi' : 'shafi');
    await p.setBool(_kNotifEnabled, s.notificationsEnabled);
    await p.setInt(_kPreNotifMin, s.preNotificationMinutes);
    await p.setString(_kLang, s.languageCode);
    await p.setString(_kTheme, _encodeTheme(s.theme));
    if (s.manualLatitude == null) {
      await p.remove(_kManLat);
      await p.remove(_kManLng);
      await p.remove(_kManCity);
    } else {
      await p.setDouble(_kManLat, s.manualLatitude!);
      await p.setDouble(_kManLng, s.manualLongitude!);
      if (s.manualCityLabel != null) {
        await p.setString(_kManCity, s.manualCityLabel!);
      }
    }
    await p.setBool(_kAutoDetect, s.autoDetectMethod);
    await p.setBool(_kGpsChosen, s.gpsChosen);
  }

  ThemePreference _decodeTheme(String? raw) {
    switch (raw) {
      case 'light':
        return ThemePreference.light;
      case 'dark':
        return ThemePreference.dark;
      default:
        return ThemePreference.system;
    }
  }

  String _encodeTheme(ThemePreference t) {
    switch (t) {
      case ThemePreference.light:
        return 'light';
      case ThemePreference.dark:
        return 'dark';
      case ThemePreference.system:
        return 'system';
    }
  }
}
