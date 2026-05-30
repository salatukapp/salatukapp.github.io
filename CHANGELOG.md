# Changelog

## [0.2.2] — 2026-05-31

### Fixes the recurring "still broken after deploy" problem
- **Root cause of stale content:** `main.dart.js` / `flutter_bootstrap.js` were cached `immutable` for 1 year, but Flutter web doesn't content-hash them — so returning visitors were frozen on old app code (this is why "University of Karachi" still showed for users even after it was removed server-side). Cache headers are now `no-cache, must-revalidate`: the browser keeps a copy but always revalidates (cheap 304 when unchanged, fresh on every deploy). Stale builds can no longer get stuck.

### Faster, smoother boot
- CanvasKit (Flutter's renderer) is now **bundled and served same-origin** (`--no-web-resources-cdn`) instead of fetched from `gstatic.com` at startup — removes a cross-origin round trip that was slow on poor links.
- Branded loading spinner shows immediately (no blank/white flash).
- Service-worker cleanup only triggers a one-time reload when an old SW is actually controlling the page, eliminating a spurious reload "glitch" on load.

### Qibla 90° shift fixed
- Removed the `screen.orientation.angle` compensation added in 0.2.0: when a phone auto-rotated, the angle flipped 0→90 and the heading jumped exactly 90°. The compass now assumes the natural (portrait) orientation — how a Qibla compass is held — and the exact great-circle bearing (the number) is always shown and never moves. iOS keeps using the OS-corrected `webkitCompassHeading`.

### Notifications removed on web
- The notifications section is hidden on the web app (browsers can't schedule background prayer alarms). It remains functional on the native Android APK.

## [0.2.1] — 2026-05-26

- Removed the "University of Karachi" calculation method from the app. No replacement method was added to the list. Internal fallback/default now resolves to Moonsighting Committee (which shares the same 18° Fajr, so computed times for affected regions are essentially unchanged). The city of Karachi remains available as a manual location.

## [0.2.0] — 2026-05-26

A 57-agent adversarial audit (7 dimensions: logic, layout, iPhone-Safari, Android, security, web standards, accessibility) found 39 confirmed issues. All critical/high and most medium/low are fixed in this release.

### Critical / High
- **Android web Qibla fixed (the wrong-direction bug):** the compass now (a) converts `alpha` correctly as `360 − alpha` (W3C alpha is counter-clockwise), (b) only accepts **absolute** orientation frames so an arbitrary-zero relative frame can't poison the heading, and (c) compensates for `screen.orientation.angle` in landscape. A pure `CompassMath.headingFromAlpha` helper + regression tests (alpha 0/90/180/270 → N/W/S/E) prevent future inversions.
- **Invalid compass readings filtered** (null / negative / NaN headings no longer peg the needle to north).
- **Branded app icons:** replaced the default Flutter logo across favicon, web PWA icons (incl. maskable), and Android launcher/adaptive icons with an emerald + gold crescent-and-star mark.
- **Hero "Fajr (tomorrow)" overflow fixed** — the 48px next-prayer label now scales to fit on narrow phones.
- **Light-mode contrast pass (WCAG):** darker hero gradient, readable secondary-text token, darker "NOW" badge — secondary text now clears 4.5:1.

### Medium
- GPS choice now persists (no more first-run location prompt on every launch).
- Desktop redirect now gates on `shortestSide` — a landscape iPhone/iPad no longer gets the "download the APK" screen.
- iPhone PWA status bar set to opaque so the header isn't drawn under the notch.
- Privacy policy reconciled with reality: removed the false "encrypted SQLite" and App-Store/Play claims; the Qibla "verify on IslamicFinder" button no longer transmits your coordinates.
- Accessibility: compass exposes a live screen-reader instruction; Arabic adhkar carry RTL semantics; reduced-motion respected; bigger touch targets + tooltips.

### Low / polish
- Real CSP delivered as an HTTP header (so `frame-ancestors` takes effect) + `X-Frame-Options: DENY`.
- Open Graph / Twitter card tags, on-brand pre-boot loader (no white flash), `<html lang>`, `<noscript>`, manifest `id`/`lang`/`dir`/`categories`.
- `AmiriQuran` font registered; dead `generate: true` removed; `mounted` guard on adhkar load error; WMM `isExpired()` maintenance signal.
- 70 unit tests passing (added compass-heading mapping tests).


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
- Removed the "Egyptian General Authority" calculation method per maintainer preference. Users in Egypt and the Levant now default to a different regional method; they can pick any of the remaining methods manually.
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
- Multiple Sunni calculation methods: ISNA, Umm al-Qura, Singapore, Türkiye (Diyanet), Moonsighting Committee, Dubai, Algerian, Tunisia, Morocco, Jordan, Gulf Region, Portugal, France (UOIF), Russia, Indonesia, Kuwait, Qatar
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
