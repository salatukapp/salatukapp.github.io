# Salatuk

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Android](https://github.com/salatukapp/salatukapp.github.io/actions/workflows/android-release.yml/badge.svg)](https://github.com/salatukapp/salatukapp.github.io/actions/workflows/android-release.yml)
[![Web](https://github.com/salatukapp/salatukapp.github.io/actions/workflows/web-deploy.yml/badge.svg)](https://github.com/salatukapp/salatukapp.github.io/actions/workflows/web-deploy.yml)
[![Try it](https://img.shields.io/badge/try%20it-omarkaaki.me%2Fsalatuk-blue)](https://salatukapp.github.io/)

A free, open-source Sunni Islamic companion app for daily prayers, Qibla direction, and authenticated adhkar. Offline-first, no tracking, no ads, no accounts.

**Live web app:** https://salatukapp.github.io/
**Android APK:** [Latest release](https://github.com/salatukapp/salatukapp.github.io/releases/latest)
**Package id:** `com.salatuk.salatuk`
**Platforms:** Android, Web (PWA). iOS via PWA only — see [Distribution](#distribution) below.
**Framework:** Flutter 3.44 / Dart 3.12

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

## Distribution

| Channel | Cost | Status |
|---|---|---|
| Web / PWA (GitHub Pages) | free | ✅ live at https://salatukapp.github.io |
| GitHub Releases (signed APK) | free | ✅ at [releases](https://github.com/salatukapp/salatukapp.github.io/releases) |
| F-Droid | free | 📋 `.fdroid.yml` ready; submission to fdroiddata pending |
| Amazon Appstore | free | 📋 metadata in `fastlane/`; submission pending |
| Huawei AppGallery | free | 📋 metadata in `fastlane/`; submission pending |
| Google Play | $25 one-time | ⏭️ deliberately skipped; AAB available at releases |
| Apple App Store | $99/yr | ⏭️ deliberately skipped; iOS use the PWA |

## Religious accuracy

Every prayer-time calculation method has been cross-verified against three independent reference implementations:
- [Batoul Apps Adhan library](https://github.com/batoulapps/adhan)
- [PrayTimes.org](http://praytimes.org/calculation/) by Hamid Zarrabi-Zadeh
- [Aladhan API](https://aladhan.com/calculation-methods)

Adhkar are sourced from:
- *Hisn al-Muslim* (حصن المسلم) by Sa'id ibn Ali ibn Wahf al-Qahtani
- *Al-Adhkar* by Imam al-Nawawi
- Primary hadith collections (Sahih al-Bukhari, Sahih Muslim, Sunan al-Tirmidhi, Sunan Abi Dawud, Sunan Ibn Majah)

Every dhikr entry in the app includes Arabic text, transliteration, English translation, repetition count, hadith citation, and authentication grade. **No weakly-authenticated narrations are included.**

See [RESEARCH.md](RESEARCH.md) for the full 3-source verification report (717 lines, 70 KB).

## License

MIT — see [LICENSE](LICENSE). Adhkar content is in the public domain and attributed to its original sources within the app.
