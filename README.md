# Salatuk

A Sunni Islamic companion app for daily prayers, Qibla direction, and authenticated adhkar.

**Package id:** `com.salatuk.mobile`
**Platforms:** Android, iOS
**Framework:** Flutter

## Features

- **Five daily prayer times** — Calculated locally using astronomical methods recognized by major Sunni authorities. Supports MWL, ISNA, Egyptian, Umm al-Qura, Karachi, Kuwait, Qatar, Singapore, Turkey (Diyanet), and MoonsightingCommittee methods. Auto-detects a sensible default based on your region. Asr juristic rule selectable (Standard / Hanafi).
- **Qibla compass** — Great-circle bearing to the Kaaba (21.4225°N, 39.8262°E) using device GPS + magnetometer. Includes calibration prompts and a map fallback.
- **Authenticated daily adhkar** — Morning, evening, after-prayer, and before-sleep remembrances sourced from Hisn al-Muslim, Imam al-Nawawi's Al-Adhkar, and primary hadith collections. Each dhikr includes Arabic text, transliteration, English translation, repetition count, and hadith citation.
- **Local notifications** — Optional prayer time alerts scheduled on-device. No server, no push.
- **Offline-first** — Works with no internet connection. Everything calculated locally.
- **Bilingual** — English and Arabic (RTL).
- **Privacy** — Zero data collection. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## Religious accuracy

This app is for Sunni Muslims. All adhkar are taken from authenticated (sahih/hasan) sources. Prayer time calculations are cross-verified against three independent reference implementations. See [RESEARCH.md](RESEARCH.md) for full source documentation.

## Development

### Prerequisites
- Flutter SDK (stable channel)
- Android SDK with API 34+
- JDK 17
- For iOS: macOS with Xcode 15+

### Setup
```powershell
flutter pub get
flutter pub run flutter_launcher_icons
```

### Run
```powershell
flutter run                  # debug build
flutter run --release        # release build
```

### Test
```powershell
flutter test                 # unit + widget tests
flutter test integration_test  # e2e on device/emulator
```

### Release builds
```powershell
# Android
flutter build appbundle --release    # for Play Store
flutter build apk --release          # sideloadable APK

# iOS (on macOS only)
flutter build ipa --release
```

## License

To be decided before publish. Likely MIT for code, with adhkar data attributed to original sources.
