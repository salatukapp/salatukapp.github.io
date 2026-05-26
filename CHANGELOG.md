# Changelog

## [0.1.2] — 2026-05-26

### Changes
- Removed the "Egyptian General Authority" calculation method per maintainer preference. Users in Egypt and the Levant now default to Muslim World League (MWL); they can still pick any of the 19 remaining methods manually.
- **iPhone Safari live compass support.** Implemented a custom DeviceOrientationEvent web shim that uses `webkitCompassHeading` on iOS Safari (already true-north corrected) and the `deviceorientationabsolute` event on Android Chrome. iOS shows an "Enable live compass" button which triggers the one-time permission prompt — this satisfies Apple's user-gesture requirement. Without permission, the static-bearing view is shown as a fallback.

## [0.1.1] — 2026-05-26

### Premium UI pass
- New emerald + gold palette with rich dark mode
- Hero gradient header on Prayer Times with live countdown
- Smoother Qibla compass with low-pass filtered needle and animated rotation
- Gradient cards on the Adhkar overview, color-coded per category
- Animated dhikr counter with bounce feedback and haptic on tap
- New bottom-nav with morphing icons and rounded top corners
- Smooth page transitions between tabs
- Polished error and loading states

### Web / desktop
- Desktop browsers now see a "designed for mobile" landing page with APK download and a copy-link button. A "continue anyway" link is available for desktop users who want to proceed.
- Static-bearing Qibla view on browsers (no live compass needle in any browser — added an honest explanation)
- Viewport meta tag added so iOS Safari renders at proper width
- Hard timeout on location requests so the UI never hangs

### Fixes
- "Pick a city" fallback (28 major cities) for any location failure
- Kotlin/Java target consistency across plugin subprojects on Android
- Core library desugaring enabled for `flutter_local_notifications`

## [0.1.0] — 2026-05-26

Initial release.

### Prayer times
- 20 Sunni calculation methods: Muslim World League, ISNA, Egyptian, Umm al-Qura, Karachi, Singapore, Türkiye (Diyanet), Moonsighting Committee, Dubai, Algerian, Tunisia, Morocco, Jordan, Gulf Region, Portugal, France (UOIF), Russia, Indonesia, Kuwait, Qatar
- Asr juristic rule selector (Standard / Hanafi)
- Region-based auto-detection of the appropriate method, with manual override
- Umm al-Qura: automatic +30 min Isha adjustment during Ramadan
- Hijri calendar display
- Live countdown to next prayer

### Qibla
- Great-circle bearing to the Kaaba (21.4225°N, 39.8262°E)
- Magnetometer-based compass with magnetic-declination correction
- Visual compass with North marker and Qibla needle

### Adhkar
- 64 authenticated entries: 22 morning, 20 evening, 9 after-prayer, 13 before-sleep
- Every entry verified in Hisn al-Muslim with primary hadith citation
- Arabic text with tashkeel, transliteration, English translation
- Per-entry tap counter for repetitions

### Other
- Scheduled prayer notifications (with optional pre-prayer reminder)
- Light/dark theme
- Privacy-first: zero data collection, all calculation on-device, no third-party SDKs
- 47 unit tests covering prayer math, Qibla bearings, region detection, and adhkar data integrity

### Known limitations
- Magnetic declination uses a centered-dipole approximation (~±2° accuracy globally). Full WMM 2025 implementation tracked for a future release.
- Türkiye (Diyanet) method may deviate from official Diyanet tables by ±2-4 min in some seasons.
- English UI only in this release; Arabic localization planned.
- iOS native build deliberately skipped to keep the project 100% free — iOS users can install the web app to home screen as a PWA.
