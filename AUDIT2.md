# Salatuk Full Audit (multi-agent)

## Executive summary

Salatuk is in solid shape overall: prayer-time math, the WMM declination model, and the dark-mode UI are sound, and the web/PWA self-healing and security headers are thoughtfully done. A 7-dimension adversarial audit produced **35 confirmed issues** after merging duplicates: **1 critical**, **3 high**, **10 medium**, and **21 low/polish**. The most serious problems cluster in the **Android Chrome web Qibla compass** (a heading that is mirror-inverted and frame-mixed — wrong for a primary shipping target) and in **brand/professionalism** (every app icon is still the default Flutter logo). Light-mode contrast and a daily hero-row overflow round out the must-fix tier.

---

## Critical (must fix before wider release)

### A1 / L1 — Android Chrome web Qibla heading is mirror-inverted AND mixes two reference frames
*(found by: logic-correctness L1, android A1, android A3 — same handler, same root cause)*

**File:** `lib/core/qibla/web_compass_web.dart:53-91` (consumed by `lib/core/qibla/qibla_service.dart:99-125`)

**Problem:** Three compounding defects in the one shared `deviceorientation` handler make the Qibla needle unreliable for every Android Chrome / PWA web user (a primary ship channel):
1. **Inverted sense (android A1, high):** the recently-removed `360 - alpha` conversion was correct. Per the W3C/Chromium spec, `deviceorientationabsolute.alpha` increases *counter-clockwise* (alpha 0=N, 90=W, 180=S, 270=E), while a compass heading is clockwise. Passing `alpha` straight through `_normalize(alpha)` mirrors the heading about the N-S axis — correct only near N/S, up to ~180° wrong near E/W. The added east declination then compounds the error.
2. **Frame mixing (logic L1, high):** the handler is registered on BOTH `deviceorientationabsolute` (absolute, true-north) and plain `deviceorientation` (relative, arbitrary zero) at lines 85-86 and never checks `event.absolute`, so it emits both as if both were compass headings — the needle jumps between two reference frames.
3. **No absolute gate / silent wrong (android A3, medium):** on magnetometer-less Android devices only the relative `deviceorientation` fires; its arbitrary-zero alpha is published as a real heading with no warning, since the web path never sets `sensorAccuracy`.

The iOS Safari path is unaffected (the `webkitCompassHeading` early-return at lines 57-64 fires first and is genuinely clockwise/true-north). The native APK is unaffected (it uses `flutter_compass_v2`).

**Fix:** In the alpha branch (lines 73-79), (a) restore the inversion: `controller.add(_normalize(360 - alpha))`; (b) gate on the event's `absolute` flag — read `jsEvent.getProperty<JSAny?>('absolute'.toJS)` and only treat alpha as a heading when it is `true`, which naturally drops the relative `deviceorientation` frames; (c) when no absolute heading is ever obtained, surface a "compass not absolute / uncalibrated" state in `qibla_screen.dart` instead of rendering a misleading needle. Leave the `webkitCompassHeading` branch (57-64) unchanged. Fix the now-wrong comment at 66-72 (spec alpha is CCW). Add a unit test asserting alpha 0→0 N, 90→270 W, 180→180 S, 270→90 E so this can't regress (today `test/unit/qibla_test.dart` only covers the pure-math bearing).

---

## High

### W1 — All app icons are still the default Flutter blue logo
**File:** `web/favicon.png`; `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`; `android/app/src/main/res/mipmap-*/ic_launcher.png`; `assets/icons/.gitkeep`

**Problem:** Every shipped icon — browser-tab favicon, iPhone "Add to Home Screen" PWA icon, Android Chrome PWA icon, and the native APK launcher — renders as the stock Flutter blue "F", not the Salatuk emerald/gold brand used everywhere else. `assets/icons/` holds only an empty `.gitkeep`, so there is no branded source icon in the repo and no `flutter_launcher_icons` config. The maskable icons are especially bad: Android crops them to a circle/squircle, so the off-center Flutter mark gets clipped. This makes a finished product look like an unfinished template across all four distribution surfaces' most visible touchpoint.

**Fix:** Design one branded master icon (emerald `0xFF1E6B52` + gold `0xFFC9A961`, e.g. the ﷺ / صَلَاتُكَ motif from `desktop_redirect.dart`) and commit the source to `assets/icons/`. Add `flutter_launcher_icons` to `pubspec.yaml` (config block with `image_path`, `web.generate`, `adaptive_icon_background/foreground`) and regenerate favicon, web Icon-192/512, the maskable pair (pad the mark inside the ~80% safe zone), and all Android mipmaps. Optionally add an adaptive launcher (`mipmap-anydpi-v26/ic_launcher.xml`).

### responsive-L1 — Hero "next prayer" Row overflows on narrow phones every evening after Isha
**File:** `lib/features/prayer_times/prayer_times_screen.dart:485-511`

**Problem:** The big next-prayer Row places a 48px-bold label and the time side by side with only a fixed 12px gap, and neither child is wrapped in `Flexible`/`Expanded`/`FittedBox`. After Isha, the label becomes `"Fajr (tomorrow)"` (the fallback at line 209) — ~326px wide alone, ~413px for the full Row. Usable width inside the 24px padding is only ~272px (320px iPhone SE), ~312px (360px Android), ~364px (412px Pixel). So a RenderFlex overflow (yellow/black stripe) fires deterministically every evening on every common phone — and the `1.25x` text-scale clamp in `main.dart:70` makes the worst case +150..+242px. This hits the app's primary screen on its primary deployment target (iPhone Safari/PWA, Android).

**Fix:** Wrap the label `Text` in `Flexible` + `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft)` so the 48px line shrinks to fit. Optionally also shorten `_nextPrayer` (line 209) to return `'Fajr'` and render `tomorrow` as a small separate badge so the 48px line never carries the parenthetical.

### A1 (accessibility) — Light-mode hero text fails WCAG contrast across the whole gradient
**File:** `lib/ui/theme/app_theme.dart:218-227` (gradient) consumed by `lib/features/prayer_times/prayer_times_screen.dart:459-542`

**Problem:** In light mode the hero gradient runs emerald `#1E6B52` → `#2D8F6E` → `#3FA37D`. All the small secondary labels (place/date `white@0.8/0.85`, hijri+time `goldSoft #E6D29B`, method `white@0.55`, NEXT PRAYER `white@0.65`, GPS `white@0.7`, countdown white-on-`white@0.12` chip) are normal-weight or sub-18px text needing 4.5:1, and they fail that bar not just at the bottom but over the *darkest* top stop too (e.g. method 3.11:1, NEXT PRAYER 3.71:1, goldSoft 4.29:1), collapsing to 1.94–3.34:1 over the lighter stops. Light mode is the default whenever the OS is in light mode. (Dark-mode hero is fine; the 48px next-prayer name passes the 3:1 large-text bar everywhere and needs no change.)

**Fix:** In `AppTheme.heroGradient` make the `light()` stops as dark as `dark()` — e.g. `[emeraldDeep #0E4A37, emerald #1E6B52, #1A5A45]` so the lightest stop stays ≤ `#1E6B52` (solid white clears 6.4:1). Then raise the secondary-label alphas (method 0.55→≥0.8, NEXT PRAYER 0.65→≥0.85, GPS 0.7→≥0.85, place/date ≥0.85) and replace `goldSoft` on the hijri/time text with a deeper gold or near-opaque white. Apply the same darkened light gradient to `qibla_screen.dart:107`, `location_first_run.dart:67`, `desktop_redirect.dart:68`.

---

## Medium

### L2 (logic) — GPS users re-prompted with the first-run location screen on every launch
**File:** `lib/ui/widgets/location_first_run.dart:184-195`

**Problem:** `LocationGate._check()` sets `_ready` true only when a manual lat/lng is stored (line 188). The GPS path (`_useGps` → `onReady`) marks `_ready` true for the live session but persists nothing — `LocationService.getCurrent()` is in-memory only and `SettingsStore` has no GPS cache. So on every cold start `manualLatitude` is still null and the full-screen "Where are you?" chooser appears again for the entire GPS cohort, contradicting that screen's own "the browser will ask for permission once" copy. The app still works (re-tap GPS), so it's mandatory friction, not a dead end.

**Fix:** Persist the GPS choice. Add a `SettingsStore` bool `gpsChosen` (preferred over reusing `manualLatitude`, which the prayer/qibla screens treat as a frozen manual override that skips live GPS). Save it in `_useGps()` after `getCurrent()` succeeds, and update `_check()` to `_ready = (manual lat/lng set) || gpsChosen`.

### iphone-P1 / responsive-L5 — Desktop-redirect width threshold (≥720) wrongly diverts valid touch users
*(found by: iphone-safari-web P1, responsive-layout L5 — same `width >= 720` gate)*

**File:** `lib/ui/widgets/desktop_redirect.dart:273-279`

**Problem:** `ResponsiveGate` decides "desktop" purely from `MediaQuery.size.width >= 720`. Because it reads raw width (not `shortestSide`), large iPhones in **landscape** (14/15/16 Pro Max ~932, Plus ~926, 12-15 standard ~844) exceed 720 and get the DesktopRedirect — whose CTA is "Get the Android APK" and "Copy link to open *on your phone*", nonsense for someone already on an iPhone. Rotating a portrait iPhone mid-session yanks them into this screen. The same threshold also diverts **iPad Safari** (768–1024) and unfolded foldables. iOS Safari ignores the manifest `portrait-primary` lock, so this fires in production. Escapable via "Continue anyway", so it's confusing-wrong-content, not a hard lockout.

**Fix:** Gate on `shortestSide` so orientation doesn't matter: `final shortest = MediaQuery.of(context).size.shortestSide; final isDesktop = shortest >= 600;`. A phone's shortestSide stays ~430 in both orientations; iPads (≥744) and desktops still redirect. If iPads should reach the app, raise to `>= 1100` or combine with a coarse-pointer check. Also soften the DesktopRedirect copy for tablet-class devices (the static Qibla bearing, prayer times, and adhkar all work without a magnetometer).

### iphone-P2 — PWA status bar is black-translucent but Flutter web ignores safe-area insets
**File:** `web/index.html:56`

**Problem:** The standalone PWA sets `apple-mobile-web-app-status-bar-style=black-translucent`, extending the web view under the notch/status bar and over the home indicator. Flutter web never populates `MediaQuery.padding/viewPadding` from CSS `env(safe-area-inset-*)` (verified against the engine: the web `ViewConfiguration` is a const zero, and only `viewInsets` for the keyboard is ever mutated). So every `SafeArea` in the app (`qibla_screen.dart:108`, `prayer_times_screen.dart:394`, the bottom nav with `extendBody:true`) is a no-op as an installed PWA: the top header renders under the status bar and the rounded NavigationBar overlaps the home-indicator area. Less visible in plain Safari (browser chrome covers those regions); taps still register.

**Fix:** One-line: change `black-translucent` → `black` (opaque dark bar that reserves the top strip and matches the dark-green theme; avoid `default`, which is white). For a fully correct fix that also protects the bottom region, add a JS shim that reads `env(safe-area-inset-*)` into CSS vars, expose them to Dart, and inject them into `padding/viewPadding` via a `MediaQuery` override in `main.dart`'s builder. Note `SystemChrome.setSystemUIOverlayStyle` is a no-op on web.

### security-P1 — Privacy policy says location is "never sent to any third party" but the IslamicFinder button transmits exact coordinates
**File:** `lib/features/qibla/qibla_screen.dart:517-520, 552, 609`; `PRIVACY_POLICY.md:7,16,31`

**Problem:** The Qibla accuracy panel's "IslamicFinder Qibla" button builds `https://www.islamicfinder.org/world/qibla/?latitude=$latitude&longitude=$longitude` from the **raw, full-precision** GPS doubles and opens it via `url_launcher`, sending the user's exact location (plus IP/referrer) to a third party. This contradicts `PRIVACY_POLICY.md:16` ("never sent to us or to any third party"), `:7`, and `:31`, and the in-panel text at `qibla_screen.dart:552` ("Nothing is sent over the network.") sitting directly above the button. (The Google Qibla button at line 524 opens a bare URL and does NOT leak.) User-initiated to a Qibla site, so limited real-world harm — but a factual contradiction of an absolute published claim.

**Fix:** Preferred — in `_openIslamicFinder` drop the query params and open the bare `https://www.islamicfinder.org/world/qibla/` (mirroring `_openGoogleQibla`); IslamicFinder geolocates itself and the user already sees their bearing. Alternatively, keep coordinates but reconcile `PRIVACY_POLICY.md:16/31` and fix the false `qibla_screen.dart:552` sentence.

### security-P2 — Privacy policy claims an "encrypted SQLite database" but data is plaintext SharedPreferences
**File:** `PRIVACY_POLICY.md:36`; `lib/core/storage/settings_store.dart:80-119`

**Problem:** `PRIVACY_POLICY.md:36` states data "is stored locally on your device in an encrypted SQLite database." The only persistence layer is `SharedPreferences` (plaintext XML on Android, `localStorage` on web) — no SQLite, no encryption anywhere (no `sqflite`/`sqlcipher`/`drift`/`flutter_secure_storage` in `pubspec.yaml`). Manual lat/lng is stored in cleartext (`setDouble` at lines 112-113). The policy also lists "favorited adhkar, prayer history" features that don't exist/persist. A misrepresentation of a security control in a policy that claims Play/App-Store distribution; data does genuinely stay on-device, so it's compliance, not exploit.

**Fix:** Edit `PRIVACY_POLICY.md:36` to describe real storage ("…stored locally using the platform's standard local storage (Android SharedPreferences / browser localStorage), in plaintext within the app's private storage…") and drop the SQLite/encryption claim and the nonexistent favorites/history mention. If at-rest encryption is wanted, implement it (e.g. `flutter_secure_storage`) before claiming it.

### accessibility-A2 — Arabic adhkar have no Semantics/RTL hint; CustomPaint compass is silent to screen readers
**File:** `lib/features/adhkar/adhkar_list_screen.dart:240-247`; `lib/features/qibla/qibla_screen.dart:327-365, 671-759`

**Problem:** Arabic dhikr is wrapped only in a visual `Directionality(rtl)` for layout — no `Semantics` and no per-string language anywhere (there are zero `Semantics` widgets in all of `lib/`). The Qibla compass is built entirely from `CustomPaint` painters with no `semanticsBuilder`, so it exposes no accessible node and a blind user gets no actionable "turn N°" readout even as the live instruction updates. (Caveat: true per-string Arabic-TTS-voice tagging is not exposed by Flutter's Semantics API on web — rely on the screen reader's own script auto-detection + a document `lang`; the achievable wins are the RTL-aware label and the live compass value.)

**Fix:** Wrap the Arabic `Text` in `Semantics(label: entry.arabic, textDirection: TextDirection.rtl, child: …)`. Wrap the compass painter Stack in `Semantics(label: 'Qibla compass', value: <turn instruction>, liveRegion: true, child: ExcludeSemantics(child: …))` and rebuild `value` each frame from `reading.deltaToQibla`.

### accessibility-A3 — Light-mode secondary text (`cs.outline #A89F8A`) is ~2.0–2.5:1 across three screens
**File:** `lib/ui/theme/app_theme.dart:46`; used in `prayer_times_screen.dart:285,322,609,622,646`, `adhkar_list_screen.dart:74,215,252,321`, `adhkar_categories_screen.dart:115`, `qibla_screen.dart:553,594,604,628,648,664`

**Problem:** The light `outline = #A89F8A` is the standard secondary-text token: "Computing prayer times…", the Sunrise `subtle` row, error body, dhikr number badge, transliteration, translation hint, source citation, "X of Y complete", and accuracy-panel labels. On the ivory/low surfaces these compute to 2.35–2.48:1 (badge on surfaceContainerHigh 2.04:1) — far below 4.5:1 and even below the 3:1 large-text floor. A systemic WCAG 1.4.3 failure on body text, on the default (system-light) path. The `qibla_screen.dart:664` hint at `alpha 0.7` is ~1.8:1.

**Fix:** Stop using `cs.outline` for any text role in light mode. Define a readable secondary token (~`#5E5640` ≈ 6.5:1 on ivory, ~5.65:1 on surfaceContainerHigh) and substitute it at every text site above; drop the `alpha:0.7` on the qibla hint. Keep `#A89F8A` only for decorative roles (drag handle, `location_off` icon). Alternatively set an explicit dark `onSurfaceVariant` in the light `ColorScheme` and use that.

### accessibility-A4 — No reduced-motion support; the live-rotating compass ignores `disableAnimations`
**File:** `lib/features/qibla/qibla_screen.dart:318-353` (primary); also `prayer_times_screen.dart:50-52`, `adhkar_categories_screen.dart:127-141`, `adhkar_list_screen.dart:287-291`, `home_screen.dart:29-49`

**Problem:** Nothing checks `MediaQuery.disableAnimations` (set by iOS Reduce Motion / Android Remove animations), which Flutter web wires to CSS `prefers-reduced-motion` on the shipped platforms. The strongest concern is the Qibla `AnimatedRotation` dial+arrow continuously tracking the magnetometer in real time — a recognized vestibular trigger that is not user-initiated per frame. (Several other listed items are short one-shot transitions; the static GPS dot is not actually animated.)

**Fix:** Read `final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;`. When true, set the two compass `AnimatedRotation` durations (`qibla_screen.dart:332,338`) to `Duration.zero` (snap) or render a static arrow; collapse the categories stagger to opacity 1/no translate; set the `AnimatedSwitcher`/`AnimatedContainer`/bump durations to `Duration.zero`.

### accessibility-A5 — Hero refresh chip and location text are sub-44px touch targets with no label
**File:** `lib/features/prayer_times/prayer_times_screen.dart:402-428`

**Problem:** The refresh control is a bare `GestureDetector` over a Container (`padding: h8,v4` around a 14px icon ≈ 30×22px) — under the 44×44 (iOS)/48×48 (Android) minimum and exposing no button role/label. The location label beside it is a `GestureDetector` over a 13px Text (~18px tall) with no affordance — also undersized, not obviously tappable, and invisible to screen readers. (Both actions have redundant discoverable paths in the error state, so it's polish-level, not breakage.)

**Fix:** Replace the refresh `GestureDetector` with `IconButton(onPressed: onRefresh, tooltip: 'Refresh location', icon: Icon(Icons.refresh_rounded))` (48px hit area + role), or keep the chip but wrap in `Semantics(button: true, label: 'Refresh location')` with `BoxConstraints(minWidth: 48, minHeight: 48)`. For the place label, wrap the tap in `Semantics(button: true, label: 'Change location')`, give it ≥44px height, and add a subtle affordance (underline/chevron).

### accessibility-A6 — Gold "NOW" badge unreadable in light mode (1.8:1)
**File:** `lib/features/prayer_times/prayer_times_screen.dart:626-637`

**Problem:** The "NOW" label on the current-prayer card uses `AppTheme.gold (#C9A961)` at 10px/w800 over a gold@0.18-tinted card on ivory → ~1.88:1, far below both 4.5:1 and the 3:1 large-text floor (the 10px badge isn't large text). Dark mode is fine. In light mode the gold icon (~1.88:1) and gold border (~1.33:1) on the active card are also weak, so the only robust active-card cue is font weight.

**Fix:** In light mode render the badge in a darkened gold. At line 631 use `color: isDark ? AppTheme.gold : cs.onSecondaryContainer` (`#4A3C0F` ≈ 9.0:1 on that background; `isDark` is already in scope). Avoid `#8B6B3D`/tertiary (~4.1:1 — borderline for a 10px badge). Also darken the active-card icon (line 608) and strengthen the border (line 588) in light mode.

---

## Low / polish

### L3 (logic) — `setState` in adhkar load-error path has no `mounted` guard
**File:** `lib/features/adhkar/adhkar_categories_screen.dart:40-43`

**Problem:** `_load()` guards its success path with `if (mounted)` (line 36) but the `catch` block calls `setState` unconditionally (line 41). If the widget is disposed before the async asset load fails (and `fromJson` does throw on malformed JSON), this throws "setState() called after dispose()". Very low probability — it's a bundled, cached asset — but an asymmetric latent crash.

**Fix:** Add `if (!mounted) return;` before the `setState` in the catch block to match the success path.

### L4 (logic) — Prayer screen rebuilds the entire scroll view + hero every second
**File:** `lib/features/prayer_times/prayer_times_screen.dart:50-53`

**Problem:** A 1-second `Timer.periodic` calls `setState((){})` on the whole state, rebuilding the full `CustomScrollView`, `_HeroHeader`, and six `_PrayerCard`s every tick just to update the countdown text — for most of the day ~59/60 ticks produce byte-identical visible output. Correctly cancelled and `mounted`-guarded (not a leak/crash); the expensive astronomy is not in `build()`. Purely wasted work.

**Fix:** Drive only the countdown via a `ValueNotifier<Duration>` and wrap just the countdown chip (lines 514-537) in a `ValueListenableBuilder`. Better: tick once per minute when >60s remain, switching to 1Hz only in the final minute.

### L5 (logic) — WMM declination silently extrapolates past the 2030 validity epoch
**File:** `lib/core/qibla/magnetic_declination.dart:130`

**Problem:** `dt = time - 2025.0` and the secular terms are applied linearly with no upper bound; WMM 2025 is only valid through 2030.0, after which accuracy quietly degrades with no warning. Not a current problem (2026 is well inside validity) and never crashes.

**Fix:** Do **not** clamp `dt` (freezing the 2030 field is *less* accurate than the linear trend for the first year or two — that part of the original suggestion is wrong). Instead add a maintainer-visible expiry signal, e.g. `assert(time < 2030.0, 'WMM 2025 coefficients expired — refresh from NOAA .COF');` and/or expose `MagneticDeclination.isExpired(date)`. The real fix is operational: refresh `_coeffs` from the successor WMM `.COF` when it ships (~2030).

### responsive-L3 — `LocationFirstRun` is a non-scrolling Column with Spacers; overflows in landscape / short heights
**File:** `lib/ui/widgets/location_first_run.dart:71-155`

**Problem:** A bare `Padding > Column` with two `Spacer()` and no `SingleChildScrollView`; fixed content exceeds ~400px. No orientation lock exists anywhere (the manifest `portrait-primary` only binds an installed PWA; native Android allows rotation). On the native APK (which bypasses the web-only `DesktopRedirect`) and on small web phones in landscape (<720px), the Spacers collapse and the Column emits a RenderFlex overflow. The error states at `prayer_times_screen.dart:305` and `qibla_screen.dart:209` share the no-scroll trait (but center, no Spacers, so overflow less).

**Fix:** Wrap the Column in `SingleChildScrollView` and replace the two `Spacer()` with `MainAxisAlignment.center` (or `ConstrainedBox(minHeight: viewport) + IntrinsicHeight`). Apply the same scroll wrap to the two `_ErrorState` Columns.

### responsive-L6 — `AmiriQuran` font for the ﷺ glyph is not registered in `pubspec`
**File:** `lib/ui/widgets/desktop_redirect.dart:108-116`; `lib/ui/theme/app_theme.dart:198-202`

**Problem:** The ﷺ glyph and `AppTheme.arabicQuran` reference `fontFamily: 'AmiriQuran'`, but `pubspec.yaml:55-60` registers only `Amiri`. Confirmed via the build's `FontManifest.json` — `AmiriQuran` is absent and the `.ttf` isn't shipped, so the glyph falls back to a system/Noto font. Cosmetic, confined to the desktop-redirect screen (wide-web only); `arabicQuran` is otherwise unused.

**Fix:** Add an `AmiriQuran` family block under `flutter.fonts` pointing at `assets/fonts/AmiriQuran.ttf`. Alternatively, since `arabicQuran` is unused, switch `desktop_redirect.dart:111` (and `app_theme.dart:199`) to the registered `Amiri` and delete the unused `.ttf`.

### iphone-P3 / web-W5 — "Copy link" copies the stale `github.io` redirect URL, not canonical `web.app`
*(found by: iphone-safari-web P3, web-standards-professional W5 — identical)*

**File:** `lib/ui/widgets/desktop_redirect.dart:38`

**Problem:** The "Copy link to open on phone" button copies `https://salatukapp.github.io/`, which now only serves a meta-refresh/redirect to `salatukapp.web.app`. Recipients (typically phone users) eat an extra hop and a brief "Salatuk has moved" interstitial on slow connections, and it's a strange link to hand someone for the canonical app.

**Fix:** Change the copied URL to `https://salatukapp.web.app/`. Leave the APK release link (line 52) and repo/Source/privacy links (57, 217) on `github.io` — those correctly point at the GitHub *repository*, not the Pages redirect.

### iphone-P4 — Live compass needle visibly swings from North on the first reading
**File:** `lib/features/qibla/qibla_screen.dart:273-285`

**Problem:** `_CompassView._smoothedHeading` initializes to 0 and each update lerps only 25% toward the real heading. On the first reading after "Enable live compass", the dial/arrow animate from North toward the true heading over ~1s — up to a ~180° sweep if the user faces south. Purely cosmetic; the numeric delta/heading text uses `reading.trueHeading` directly and is correct immediately.

**Fix:** Snap to the first reading. Add `bool _hasReading=false`; in `didUpdateWidget`, when `r != null && !_hasReading` set `_smoothedHeading = r.trueHeading`, `_hasReading = true`, and return early (skip the lerp); also seed on first build (e.g. in `initState` from `widget.reading?.trueHeading`, or guard the build's `heading`).

### responsive-L5 (iPad note) / web tablet copy
*Merged into iphone-P1 above (same 720px gate). The tablet-specific copy softening is captured in that fix.*

### security-S1 — CSP is delivered only as a `<meta>` tag; `firebase.json` sets no HTTP-header CSP
**File:** `web/index.html:45`; `firebase.json:28-37`

**Problem:** Firebase (the live host) already sets HSTS/Permissions-Policy headers but no `Content-Security-Policy`; the CSP lives only in a `<meta http-equiv>` tag, which is strictly weaker. Notably `frame-ancestors 'none'` is **ignored** in a meta tag, so that clickjacking guard is silently inert today. The stale comment at lines 26-27 still blames "GitHub Pages doesn't let us set headers" — but GH Pages now only serves a redirect.

**Fix:** Add a `Content-Security-Policy` key to the `**/*.html` headers block in `firebase.json`, copying the policy from `web/index.html:45` (this makes `frame-ancestors 'none'` take effect). Keep the meta tag as defense-in-depth, optionally add `X-Frame-Options: DENY`, and update the stale comment.

### security-S2 — CSP keeps `'unsafe-inline'` in `script-src`; could be a hash
**File:** `web/index.html:45,73-93`

**Problem:** `script-src` includes `'unsafe-inline'`, but the only inline script is the static SW-unregister IIFE (73-93); `flutter_bootstrap.js` loads external. With `'unsafe-inline'`, any injected inline `<script>` would execute. Low risk — the app has no user-generated HTML sink. (`'wasm-unsafe-eval'` is correctly the minimal WASM token; full `'unsafe-eval'` is correctly absent. The comment at line 35 misattributes `'unsafe-inline'` to Flutter boot, which is actually external-src.)

**Fix:** Drop `'unsafe-inline'` and pin the inline boot script with its `sha256-…` hash computed over the exact bytes between the `<script>` tags. A nonce won't work for a static prebuilt file. Verify against the actually-deployed `index.html`.

### security-P3 — Privacy policy claims App Store / Google Play distribution
**File:** `PRIVACY_POLICY.md:65`

**Problem:** The closing line says the policy "applies to Salatuk on Android (Google Play) and iOS (Apple App Store)." There is no native iOS build and no App Store presence (iPhone = Safari web/PWA), and Android ships as Firebase web + sideloaded APK — so it describes a different distribution than reality. Documentation accuracy only. *(The auditor's secondary claim that the calc-methods line is wrong is a false positive — every method named in `:53` is present in `sunni_method.dart`; leave line 53 alone.)*

**Fix:** Edit line 65 to: "*This policy applies to Salatuk as a web app at https://salatukapp.web.app (including the Add-to-Home-Screen PWA) and as the Android APK.*" Drop the storefront references.

### web-W2 — No Open Graph / Twitter-card / `og:image` tags; shared links show no rich preview
**File:** `web/index.html` (head, lines 19-64)

**Problem:** The head has a description and theme-color but no `og:*` or `twitter:*` tags and no share-card image asset. Since "Copy link to open on phone" is a core sharing CTA, pasted links render as bare URLs in WhatsApp/iMessage/etc. Pure marketing polish.

**Fix:** Add `og:type/url/title/description/image` and `twitter:card=summary_large_image` (+title/description/image) to the head, pointing `og:image` at a new same-origin 1200×630 `web/og-image.png`. Important: most unfurlers don't follow redirects, so either point the "Copy link" CTA at `web.app` (see W5) or add the same OG tags to the `github.io` redirect page.

### web-W3 — No first-paint loading indicator; blank white screen until CanvasKit WASM loads
**File:** `web/index.html` (body, lines 66-95)

**Problem:** The body has only the SW-cleanup script and `flutter_bootstrap.js`; no spinner, logo, or background color before first frame. The CanvasKit build fetches a multi-MB WASM blob from `gstatic.com` first, so on a slow connection users see a plain white page for several seconds — and the white flash clashes with the emerald theme (manifest `background_color` doesn't apply to a browser tab). Self-resolves within seconds.

**Fix:** Add an inline branded loader div (emerald `#0E4A37` background + centered `icons/Icon-192.png`) removed on Flutter's first frame, or at minimum set `<body style="background-color:#0E4A37">` so the pre-boot flash is on-brand.

### web-W4 — `<html>` element has no `lang` attribute
**File:** `web/index.html:2`

**Problem:** The document opens with a bare `<html>` (no `lang`), a WCAG 3.1.1 (Level A) baseline for screen-reader pronunciation and SEO. The omission propagates to the production artifact.

**Fix:** Change `<html>` to `<html lang="en">`. If Arabic localization is added later, set `lang`/`dir="rtl"` per active locale.

### web-W6 — `manifest.json` missing `categories`, `lang`, `dir`, `id`
**File:** `web/manifest.json`

**Problem:** The manifest is well-branded but omits a few polish fields used by PWA install UIs/catalogs. Purely cosmetic, no runtime effect.

**Fix:** Add `"lang": "en"`, `"dir": "ltr"`, `"id": "/"` (stable PWA identity, intentionally differs from `start_url "."`). `"categories": ["lifestyle","utilities"]` is optional and has no practical effect without an app-store listing.

### web-W7 — UI is English-only; l10n scaffolding present but unused (`generate: true` with no `.arb`)
**File:** `pubspec.yaml:49`; `lib/features/home/home_screen.dart:59-74`; `lib/features/prayer_times/prayer_times_screen.dart` (hardcoded labels)

**Problem:** All UI chrome is hardcoded English; Arabic appears only as adhkar content/flourishes. `pubspec.yaml` has `generate: true` for l10n but there is no `l10n.yaml` and no `.arb` files, so the localization machinery is half-wired and does nothing — a misleading dead config (and `flutter_localizations` is declared but never imported). Full Arabic UI is a feature, not a bug; the dead flag is the concrete defect.

**Fix:** Delete the dangling `generate: true` (line 49) — zero behavior change. Optionally drop the unused `flutter_localizations` dependency until it's wired into `MaterialApp`. Full localization later: add `l10n.yaml` + `app_en.arb`/`app_ar.arb`, register the delegates + `supportedLocales [en, ar]`, replace hardcoded strings, and rely on automatic `Directionality` for RTL.

### web-W8 — No `<noscript>` fallback for JS-disabled / failed-boot visitors
**File:** `web/index.html`

**Problem:** If JS is disabled or `flutter_bootstrap.js`/CanvasKit fails, the visitor gets a permanently blank page with no explanation — and (combined with W3) a failed boot is indistinguishable from a hang. JS-disabled mobile is rare; the common stale-SW failure is already self-healed by the existing snippet.

**Fix:** Add `<noscript>Salatuk needs JavaScript enabled to run. Please enable it and refresh.</noscript>` inside `<body>` before the scripts. Optionally add a static "still loading? refresh" hint via an `onEntrypointLoaded`/`setTimeout` shim.

### web-W9 — README "Try it" badge label still says the old personal domain
**File:** `README.md:6`

**Problem:** The shields.io badge label hard-codes `omarkaaki.me/salatuk` (the only `omarkaaki.me` reference left in the repo) while linking to `github.io`. Docs-only stale branding a contributor would notice; CHANGELOG documents the deliberate move away from the personal name.

**Fix:** Replace the badge label with one matching the destination, e.g. `[![Try it](https://img.shields.io/badge/try%20it-salatukapp.web.app-blue)](https://salatukapp.web.app/)`. Leaving lines 10/70 on `github.io` is fine — that front-door redirect is a deliberate convention.

### android-A2 — Web compass ignores `screen.orientation`; heading off by 90/180/270° in landscape
**File:** `lib/core/qibla/web_compass_web.dart:49-94`

**Problem:** `deviceorientationabsolute.alpha` is referenced to the device's natural orientation, not the current screen rotation, and the handler never reads `screen.orientation.angle`. In landscape (or on a landscape-natural device) the heading is offset by the screen angle. Independent of A1, and would remain after A1 is fixed. Bounded impact: a Qibla compass is held upright in portrait, where the angle is 0 and the error is zero. Android Chrome web only (iOS uses the screen-aware `webkitCompassHeading` branch).

**Fix:** In the alpha branch (73-79), subtract the screen angle: `controller.add(_normalize(360 - alpha - screenAngle))` (combine with the A1 inversion), reading `web.window.screen.orientation.angle`. Apply only to the alpha branch. Note: `SystemChrome.setPreferredOrientations` is a no-op on web; to lock orientation in-browser use `screen.orientation.lock('portrait')`.

### accessibility-A7 — Icon-only buttons mostly lack tooltips / semantic labels
**File:** `lib/features/adhkar/adhkar_list_screen.dart:60-63`; `lib/features/prayer_times/prayer_times_screen.dart:417`; `lib/ui/widgets/desktop_redirect.dart:233-248`

**Problem:** Only two icon-only controls have a tooltip. The Adhkar back arrow (a custom Row app bar, so no auto "Back" label) announces just "button" (WCAG 4.1.2); the hero refresh `GestureDetector` is nameless (see A5). *(The footer-link sub-claim is partly overstated — those wrap `Text`, so the visible label IS read; they only lack a button/link role and are desktop-only.)*

**Fix:** Add `tooltip: 'Back'` to the IconButton at `adhkar_list_screen.dart:60-63`. Label the refresh control (see A5). For the desktop footer links, optionally wrap in `Semantics(button: true, label: label)` — lower priority.

### accessibility-A8 — Text scaling hard-clamped at 1.25× blocks low-vision users who need ~2×
**File:** `lib/main.dart:65-74`

**Problem:** The root builder clamps `textScaler` to `maxScaleFactor: 1.25`, so a user with a 2× OS font is silently capped — below the WCAG 1.4.4 (AA) 200% benchmark. A genuine tradeoff: the 48px hero, M3 NavigationBar, and 280px compass would overflow at 2×. Not a functional break.

**Fix:** Don't raise the global clamp. Scope it by screen: keep ~1.25 for the hero/compass, but wrap the already-scrollable text screens (Adhkar `ListView` at `adhkar_list_screen.dart:102`, Settings, the `_AccuracyPanel` scroll view) in their own `MediaQuery` allowing ~1.6–2.0×, since vertical growth is absorbed by scroll. Make the hero numbers/compass reflow (`FittedBox`, `AspectRatio`) so a higher cap is safe there too. At minimum document the limit.

### accessibility-A9 — Dark-mode `outline` secondary text is borderline (3.1–4.1:1)
**File:** `lib/ui/theme/app_theme.dart:81`; used at the same text sites as A3

**Problem:** Dark `outline = #6F7873` on the dark surfaces computes to 3.83:1 (`#111C18`), 4.11:1 (scaffold `#0A1411`), and 3.15:1 (number badge on `#1F2D28`). Clears 3:1 but fails 4.5:1 for the 11–13px body copy it's actually used on. Near-miss, dark-mode only.

**Fix:** Lighten the dark text-outline or split the role. Simplest: change `outline` to ~`#8A938E` (~4.5:1 on `#1F2D28`, higher elsewhere). Cleaner: keep `#6F7873` for borders/dividers and switch the secondary *text* sites to `onSurfaceVariant`, setting a dark `onSurfaceVariant` ~`#A9B2AD`.

---

## Recommended fix order

1. **A1/L1 — Android web Qibla heading (critical):** restore `360 - alpha`, gate on `event.absolute`, add the mapping unit test. Core religious-accuracy feature, wrong on a primary channel.
2. **responsive-L1 — Hero "Fajr (tomorrow)" Row overflow:** wrap the 48px label in `Flexible` + `FittedBox`. Fires daily on every phone; trivial fix.
3. **accessibility-A1 + A3 + A6 — Light-mode contrast pass:** darken the light hero gradient and raise label alphas (A1), replace `cs.outline` text with a readable token (A3), and darken the "NOW" badge (A6). One coordinated theme change clears the worst legibility failures on the default light path.
4. **W1 — Brand the app icons:** add `flutter_launcher_icons` and a master icon, regenerate web + Android. Biggest professionalism win across all four surfaces.
5. **L2 — Persist the GPS choice (`gpsChosen` flag):** stop re-prompting the first-run chooser on every launch for the entire GPS cohort.
6. iphone-P1/responsive-L5 — switch the desktop gate to `shortestSide >= 600` (fixes landscape iPhone + iPad diversion).
7. security-P1 + P2 + P3 — reconcile the privacy policy with reality (drop coordinate leak, fix encrypted-SQLite and storefront claims).
8. iphone-P2 — change PWA status-bar style to `black` (one-line) for notch safe-area.
9. accessibility-A2, A4, A5, A7 — semantics + reduced-motion + touch-target accessibility batch.
10. android-A2 — add `screen.orientation.angle` compensation to the web compass.
11. Web/docs polish batch: P3/W5 copy-link URL, S1/S2 CSP hardening, W2 OG tags, W3 loader, W4 `lang`, W6 manifest fields, W7 dead `generate:true`, W8 `<noscript>`, W9 README badge.
12. Lowest priority: L3 mounted-guard, L4 per-second rebuild scoping, L5 WMM expiry assert, responsive-L3 scroll wrap, responsive-L6 font registration, iphone-P4 compass snap, A8 scoped text scaling, A9 dark-outline tweak.
