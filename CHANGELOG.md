# Changelog

## [0.1.4] — 2026-05-26

### Critical correctness fixes (all four from AUDIT.md)
- **Replaced the broken centered-dipole declination model with the full NOAA WMM 2025 spherical-harmonic model** (degree 12, all 91 coefficient pairs). Verified against NOAA's reference calculator for 8 cities (Beirut, Riyadh, NYC, Sydney, London, Mecca, Tokyo, Jakarta) — all within ±1° of NOAA. Previous model was 10-30° off with wrong sign in many populated regions.
- **Fixed iOS native double-declination correction.** `flutter_compass_v2` on iOS already returns `CLHeading.trueHeading` (declination-corrected); on Android it returns raw magnetic. The compass service now skips declination on iOS native and applies it only on Android, fixing a 5-20° Qibla error on iOS.
- **Wired up prayer-time notifications.** The `PrayerNotifier.reschedule` was implemented but never called — the "Athan notifications" toggle was non-functional. Now schedules the next 7 days of prayers after every bootstrap and on app resume, capped to 6 days when pre-reminders are enabled to stay under iOS's 64-pending-notification limit.
- **Fixed region-detector overlap bugs.** Dubai/UAE was being classified as Umm al-Qura (it now correctly returns Dubai). Tunisia was being classified as Algerian (now correctly returns Tunisia). Added narrow boxes for Qatar, Kuwait, Jordan before falling back to the wide Saudi+GCC box.

### Tests
- 51 unit tests passing (added 8 WMM declination tests against NOAA reference values for cities across 5 continents).

## [0.1.3] — 2026-05-26

### Brand + Web hosting
- Project moved to the dedicated **salatukapp** GitHub organization. The web app now lives at **https://salatukapp.github.io** (clean root URL, no personal name, no subpath).
- Repository renamed to `salatukapp/salatukapp.github.io` to enable the root-level user/org page URL.
- All in-app links (Settings → Privacy policy, Source code, Get the APK) updated to the new URLs.

### Security hardening (v0.1.3 also includes everything from 0.1.2)
- Content Security Policy: every third-party origin blocked
- HTTPS-only enforcement on the Pages site
- Referrer-Policy `strict-origin-when-cross-origin`
- `frame-ancestors 'none'` (clickjacking guard)
- `X-Content-Type-Options: nosniff`

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
