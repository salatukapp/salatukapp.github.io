# Salatuk Correctness Audit

**Scope:** GPS, location, prayer-time, and Qibla code paths in `lib/`.
**Date:** 2026-05-26
**Reviewer:** Automated source-audit. Where the assessment depends on
scholarly judgement (e.g. whether to round Isha differently), the finding is
flagged "needs scholar/expert review".

The labels below mean:

- **CRITICAL** — religiously sensitive correctness defect; users will see
  wrong prayer times, wrong Qibla, or no notifications at all.
- **HIGH** — non-religious reliability issue that breaks the experience for
  a class of users (high-latitudes, near IDL, etc.).
- **MEDIUM** — minor inaccuracy; the user will not be misled in a way that
  invalidates an act of worship, but the experience could be tighter.
- **CONFIRMED-CORRECT** — explicitly verified items, with reasoning.

---

## CRITICAL

### C1. Magnetic declination model is wildly inaccurate

**File:** `lib/core/qibla/magnetic_declination.dart` (entire file)

The centered-dipole approximation produces declination errors of **10–30°**
at populated mid-latitude sites — not the ±2° claimed in the file comment.
Numerical comparison against NOAA WMM 2025 (mid-2026 epoch) using the file's
constants (`_poleLatDeg = 80.65`, `_poleLngDeg = -72.68`):

| Site       | Coords          | File output | NOAA WMM | Error |
|------------|-----------------|-------------|----------|-------|
| Beirut     | 33.89, 35.50    | **-10.32°** | +5.00°   | -15° |
| Riyadh     | 24.71, 46.68    | -8.66°      | +3.40°   | -12° |
| NYC        | 40.71, -74.01   | +0.34°      | -13.50°  | +14° |
| Sydney     | -33.87, 151.21  | +8.50°      | +12.30°  |  -4° |
| London     | 51.51, -0.13    | -15.06°     | +1.00°   | -16° |
| Mecca      | 21.42, 39.83    | -9.06°      | +3.50°   | -13° |
| Tokyo      | 35.68, 139.65   | +5.63°      | -7.60°   | +13° |
| Anchorage  | 61.22, -149.90  | +19.66°     | +16.00°  |  +4° |
| Reykjavik  | 64.13, -21.94   | -20.41°     | -10.50°  | -10° |
| Cape Town  | -33.92, 18.42   | -11.24°     | -25.00°  | +14° |

The **sign is wrong** in Beirut, Riyadh, NYC, London, Mecca, Tokyo, and
Cape Town. Adding/subtracting this value will steer the Qibla needle in
the wrong direction by up to half-of-the-error degrees.

The root cause: the centered-dipole model (a single great-circle bearing to
a fixed "dip-pole" point) cannot represent the non-dipole components of the
geomagnetic field. RESEARCH.md §2.4 already recommended either the full WMM
2025 spherical-harmonic model, the `geomag` Dart package, or per-platform
native APIs (Android `GeomagneticField`, iOS `CLHeading.trueHeading`).

**This must be replaced before users rely on this app for Qibla on
Android.** Iceland users would be sent ~10° from Qibla; Cape Town users
~14° off; NYC users ~14° off. None of these are tolerable.

### C2. iOS Qibla heading is double-declination-corrected

**File:** `lib/core/qibla/qibla_service.dart:50-76` (`compassStream`)

`flutter_compass_v2` v1.0.3, on **iOS**, returns
`CLHeading.trueHeading` already corrected to true north
(`SwiftFlutterCompassPlugin.swift:45`, `let trueHeading = newHeading.trueHeading`).
On **Android** it returns magnetic azimuth — declination is NOT applied
(`FlutterCompassPlugin.kt:179-191` writes `magneticAzimuth` straight to the
event sink; the `TSAGeoMag` declination class is dead code on the data path).

`compassStream` blindly does `magneticHeading + declination` for **both**
platforms (line 65). On iOS this **double-corrects**: the user sees a
heading that is off by exactly the declination, and Qibla will be off by
the same amount (5–20° in many populated regions, even worse than C1
suggests since the C1 model's value is also wrong).

The correct fix is platform-specific: on iOS skip the declination addition;
on Android apply a *correct* declination (after C1 is fixed).

This also affects the comment in RESEARCH.md §2.4 ("flutter_compass... does
NOT automatically apply magnetic declination correction"). That paragraph
is **out of date** for `flutter_compass_v2` v1.0.3 on iOS — it does apply.

### C3. Prayer notifications never fire

**File:** `lib/core/notifications/prayer_notifier.dart` (entire file);
absence of any caller for `.reschedule(...)`.

`PrayerNotifier.reschedule(items: ...)` is implemented but **never called
anywhere in the codebase** — verified by grep (0 matches for `.reschedule(`).
`main.dart` only calls `PrayerNotifier().init()` (line 19) which sets up
the channel/permissions but never schedules anything. The
`notificationsEnabled` setting in `settings_store.dart` toggles nothing.

Users with notifications enabled will hear silence, and they will not know
the feature is broken — settings indicate it should work. For a prayer
app, missed prayers because of silent code is a release-blocker.

A caller needs to:
1. Run after location and method are known (so after `_bootstrap` finishes
   in `prayer_times_screen.dart`).
2. Iterate today + the next 6 days, build `PendingPrayer` entries from each
   day's PrayerTimes object, and pass them in.
3. Re-run on `AppLifecycleState.resumed` and ideally daily at midnight.

### C4. `Asr` is the last "current prayer" detected; Maghrib/Isha never flagged "NOW"

**File:** `lib/features/prayer_times/prayer_times_screen.dart:171-173`,
combined with `lib/core/prayer_times/prayer_times_service.dart:50-54` and
adhan_dart `PrayerTimes.currentPrayer` (lines 269-286 of the package source).

The screen calls `t.currentPrayer(date: now)` with `now = DateTime.now()`
(local). adhan_dart's implementation uses `date.isAfter(isha)` etc., which
in Dart compares **moments in time** regardless of UTC/local flag, so this
much is fine.

However, `prayer_times_service.computeFor` is invoked with
`date: now` and then **truncates the date** to `DateTime.utc(year, month, day)`
before calling `adhan.PrayerTimes` (line 52). For users **west of UTC**,
"today" in their local zone overlaps two UTC days. Specifically:

- Example: a user in Honolulu (UTC-10) at 23:30 local on Jan 19. Their
  `DateTime.now()` has `.year=2024, .month=1, .day=19` (local).
  `DateTime.utc(2024,1,19)` is Jan 19 00:00 UTC = Jan 18 14:00 Honolulu.
  adhan_dart computes "the day with civil noon ≈ longitude offset before
  UTC midnight", which lands on Jan 18 ~22:00 UTC ≈ Jan 18 12:00 local —
  i.e. it computes **yesterday's** prayer times in local terms.
- The user's screen will show yesterday's times after their local midnight,
  and `_nextPrayer` will return `Fajr (tomorrow)` referring to TODAY's Fajr
  in their frame, which is broadly OK but the displayed cards will be 24h
  stale.

This is a real issue for users west of UTC late at night. The clean fix is
`DateTime.utc(now.year, now.month, now.day)` only after passing the
**local** date components, which is what the code does — BUT then
adhan_dart still interprets the date in UTC terms and computes prayer
times for that calendar day **in UTC**, NOT in the user's local zone.

For low-longitude users (Riyadh, Beirut: longitude < ±90°), this is fine
because civil noon ≈ UTC noon ± few hours, well within the same UTC day.
For high-westward longitudes (Pacific, Alaska, US West Coast late at
night), prayer-time-of-day computations can be off by a full 24h in
display.

**Recommend:** before calling `computeFor`, ensure the date passed
represents the user's **current local civil day**, then compute via UTC
midnight of that day. The current code already does the right thing for
most of the world; the edge case is users at extreme west longitudes very
late at night. Verifying empirically with an Anchorage user at 23:30
local time is recommended before release.

Note: this is **C4** because in the worst case a Hawaii user could be
shown yesterday's Maghrib as a future event well after their actual
Maghrib has passed. That's a religiously-relevant miss.

---

## HIGH

### H1. No exposed HighLatitudeRule control in Settings

**Files:** `lib/core/prayer_times/prayer_times_service.dart:21-29`,
`lib/features/prayer_times/prayer_times_screen.dart:85-90`,
`lib/core/storage/settings_store.dart` (no persistence field).

`PrayerTimesService.computeFor` accepts `highLatitudeRule` but the prayer
screen never passes one and there is no Settings UI for it. adhan_dart
defaults to `HighLatitudeRule.middleOfTheNight` (see
`CalculationParameters.dart:42`).

For users at latitudes >55° (e.g. Reykjavik, St. Petersburg, Anchorage in
summer), middle-of-the-night is one of three reasonable Sunni choices
(also: OneSeventh, AngleBased). Each gives a different Fajr/Isha by
**10-90 min**. This is firmly a "needs scholar/expert review" choice; the
app's job is to expose the choice and explain it, not pick.

Recommend: add to Settings a "High-latitude rule" picker (None / Middle of
the Night / Seventh of the Night / Twilight Angle), and persist + thread
through.

### H2. No PolarCircleResolution exposure for Arctic users

**Files:** same as H1.

adhan_dart supports `PolarCircleResolution.aqrabBalad` (use nearest city
that has twilight) / `aqrabYaum` (use nearest day that has twilight) /
`unresolved`. Above the Arctic Circle in mid-summer, twilight may not
occur at all and Fajr/Isha will be NaN. Default is `unresolved` →
adhan_dart's `SolarTime.sunrise.isNaN` path eventually falls through to
the high-latitude rule's "safe" portion. No user-facing setting exists.

Recommend coupling with H1 in the same Settings section.

### H3. Region detector overlap: Levant uses Egypt's box

**File:** `lib/core/location/region_detector.dart:28-30`

The "Egypt + Sudan + Libya + Levant" box covers latitude 15-37, longitude
24-39 and returns `muslimWorldLeague`. But the **Saudi Arabia + GCC** box
right above it covers latitude 16-33, longitude 34-56. Boxes overlap in
latitude 16-33 × longitude 34-39 — this region includes western Saudi
Arabia (Tabuk, Jeddah, Mecca) and the Hijaz. Because Saudi is checked
first (line 17), Mecca is correctly classified as Umm al-Qura.

**However**, Sinai (Egypt) sits at roughly lat 28-31, lng 32-34 — *just*
outside the Saudi box (lng > 34 required). Cairo is at 30.04, 31.24 —
also outside (lng < 34). So Egyptians get MWL via the Levant box.
That's a defensible choice (Egyptian method was removed), but it is
inconsistent with §1.6 of RESEARCH.md which lists "Egypt → Egyptian (ID 5)
default". Confirmed correct per the removal decision; document the
deviation from RESEARCH.md.

**Cyprus** (35.1°N, 33.3°E): fails the Saudi box (lng < 34), passes
Levant box (24<lng<39, 15<lat<37). So Cyprus gets MWL — defensible.
However it also passes the Türkiye box (lat 35-43, lng 25-45). Türkiye is
checked BEFORE Levant (line 22 vs 28). Result: Cyprus → Türkiye/Diyanet.
That's borderline; Northern Cyprus is Turkish, southern Cyprus is Greek.
Greek-Cypriot Muslims will be slightly mis-served. Document or refine.

**Dubai** (25.27°N, 55.30°E): the **Saudi box** is lat 16-33, lng 34-56,
which includes Dubai. Dubai is therefore returned as `ummAlQura` — not
`dubai`. The Dubai method enum and the Dubai-specific RESEARCH.md
recommendation are both ignored by the auto-detector. This is a
**HIGH** correctness issue — Dubai users should see Dubai method by
default. Fix: add a Dubai/UAE box checked BEFORE the Saudi+GCC box, or
narrow the Saudi box to exclude the UAE coastline.

**Tunisia** (36.8°N, 10.2°E): Tunisia's box is lat 30-38, lng 7-12 (line
43). But Algeria's box (lat 18-38, lng -9-12, line 38) is checked first
and ALSO covers Tunis (which sits at lng ~10, well inside Algeria's
0-12 range). Result: Tunisia → Algerian Ministry method, not Tunisia
method. Fix: check Tunisia BEFORE Algeria, or trim Algeria's lngMax to 8.

**Casablanca** (33.6°N, -7.6°W): Morocco box is lat 27-36, lng -13 to -1
(line 33). Casablanca matches → `morocco`. **Correct.**

### H4. Magnetic-pole convention

**File:** `lib/core/qibla/magnetic_declination.dart:17-18`

The constants `_poleLatDeg = 80.65`, `_poleLngDeg = -72.68` refer to the
2025 IGRF/WMM "north dip pole" position (where the field is vertical),
NOT the centered-dipole axis intersection. For centered-dipole math, the
correct pole is closer to 80.7°N, 72.7°E. Using the dip pole in a
centered-dipole bearing formula compounds the C1 error. Pure
centered-dipole values would still be ±5-10° off for most cities, but the
file's choice makes it worse.

Either way, replace with WMM 2025 spherical-harmonic implementation
(reuse the Java `TSAGeoMag` class in the flutter_compass_v2 source, or
port `geomag` package).

---

## MEDIUM

### M1. iOS Safari permission-prompt dismissal

**File:** `lib/core/location/location_service.dart:52-69`

The flow is: `checkPermission()` → if denied, `requestPermission().timeout()` 
→ if still denied, throw `permissionDenied`. The `.timeout()` wraps the
inner request, so if iOS Safari hangs on a user dismissing the prompt by
tapping outside the dialog (which on some iOS versions does not return
'denied' immediately), it will eventually throw `LocationFailure.timeout`.

`LocationFirstRun._useGps` catches `LocationException` (line 42) and shows
the `_error` text. The user can then press the button again — but this
time `checkPermission()` returns `denied` again, and `requestPermission()`
on iOS Safari only fires the actual native prompt **once**, then silently
returns the cached denied state. The user is then stuck unless they
manually go into iOS Settings → Privacy & Security → Location Services →
Safari.

Recommend: detect repeated denial and show a help link / instructions
("Go to Settings → Safari → Location to re-enable"). Currently the user
sees the same generic "permission denied" message indefinitely.

### M2. `Timer.periodic(seconds: 1)` setState is wasteful

**File:** `lib/features/prayer_times/prayer_times_screen.dart:42-45`

`Timer.periodic` triggers `setState(() {})` every second to update the
countdown chip. This causes the entire screen tree to rebuild — including
the CustomScrollView and all PrayerCards. The PrayerCards don't change
on the second-by-second tick (only the countdown does).

For a hero screen this is okay-ish on mobile, but on web/desktop it will
cause visible jank. Recommend either:
- Wrap only the countdown chip in a `StreamBuilder<int>` driven by a
  one-second `Stream.periodic`.
- Use `AnimatedBuilder` with a `Animation<int>` controller.

This is **MEDIUM** because it doesn't affect correctness, only smoothness.

### M3. `_isCurrent` shows `sunrise` and `fajrAfter` as "current" briefly

**File:** `lib/features/prayer_times/prayer_times_screen.dart:171-173`,
adhan_dart `currentPrayer` source.

`adhan.PrayerTimes.currentPrayer(date: now)` returns `Prayer.sunrise`
between sunrise and dhuhr, and `Prayer.ishaBefore` before fajr. The
screen iterates only Fajr/Dhuhr/Asr/Maghrib/Isha and checks each against
`currentPrayer`. So between sunrise and dhuhr, NO card is marked "NOW" —
which is correct (technically Fajr is over once the sun rises and there
is no obligatory prayer). After Isha and before midnight, the Isha card
is still marked "NOW" (because the user is past Isha, before fajr-of-
tomorrow). That's fine.

But between midnight (local) and Fajr, adhan's `currentPrayer` returns
`Prayer.ishaBefore`. The screen's `_isCurrent` will match none of Fajr/
Dhuhr/Asr/Maghrib/Isha — so no card is highlighted. From a UX
perspective, Isha should arguably still be highlighted (the user is still
"in Isha's window" in the eyes of the law). Document this as expected
behavior or extend `_isCurrent` to map `ishaBefore` → Isha card.

### M4. HijriCalendar tabular vs visibility-based

**File:** `lib/core/prayer_times/prayer_times_service.dart:41-48` (uses
`HijriCalendar.fromDate(date)`)

The `hijri` Dart package computes Hijri dates using the Umm al-Qura
tabular calculation. Real-world Saudi Arabia transitions between months
based on **moon sighting**, which is often ±1 day from the tabular
calendar (particularly around Ramadan start/Eid). This means the +30 min
Ramadan adjustment may be applied 1 day late or 1 day early relative to
the official Saudi declaration.

Acceptable trade-off for an offline app, but document. Users who want
moon-sighting accuracy in Ramadan should toggle the +30 min manually
through a setting (which currently doesn't exist as a user toggle).

### M5. Web compass stream leak risk on rapid screen rebuilds

**File:** `lib/features/qibla/qibla_screen.dart:60-87`,
`lib/core/qibla/web_compass_web.dart:49-89`

`webCompassStream` returns a new `StreamController.broadcast` per call.
Listeners are attached/detached in `onListen`/`onCancel`. The qibla
screen reassigns `_stream` in `_bootstrap` and `_enableWebCompass` — each
time creating a new controller. Old controllers will have their listeners
cancelled when the `StreamBuilder` rebuilds — that's fine — but the
**event listeners** on `web.window` are removed in `onCancel`. So no
true leak. However, between `_bootstrap` reassigning `_stream` and the
new `StreamBuilder` subscription kicking in, there is a brief window
where the old controller's `onCancel` has fired and the new one's
`onListen` has not yet. During this window, **no events are observed**.
This is unlikely to be a user-visible issue but is worth noting.

### M6. Geolocator `LocationAccuracy.medium`

**File:** `lib/core/location/location_service.dart:85`

Prayer times depend on **longitude only** for solar transit; **latitude
only** for solar declination. Medium accuracy (±50-100m) is more than
enough — Qibla would shift by <0.001° at 100m. Confirmed-correct.
However, Qibla also tolerates worse — even ±1km is fine. So `medium` is
defensible. Recommend documenting why medium (not best) was chosen, in a
comment for future maintainers.

---

## CONFIRMED-CORRECT

### V1. Kaaba coordinates in adhan_dart match RESEARCH.md

**File:** adhan_dart 2.0.1 `lib/src/Qibla.dart:18` defines
`Coordinates(21.4225241, 39.8261818)`. RESEARCH.md §2.1 requires
21.4225°N, 39.8262°E ± 4 decimals. Match: **OK** (within 0.0001°).

### V2. Egyptian method is fully removed

**Files:** `lib/core/prayer_times/sunni_method.dart` — no Egyptian enum
entry. `lib/core/location/region_detector.dart:25-30` — explicitly
mentions removal and routes to MWL. Verified via grep:
only one match for "Egyptian" remains in lib/, in a comment explaining
the removal. **OK.**

### V3. Hijri-Ramadan check is correctly gated

**File:** `lib/core/prayer_times/prayer_times_service.dart:41`

`if (umAlQuraRamadanAdjustment && method == SunniMethod.ummAlQura) { ... 
if (hijri.hMonth == 9) { +30 min }; }`. Both gates required: flag must
be true AND method must be Umm al-Qura. The default flag is true. The +30
is applied to Isha only via `params.adjustments[Prayer.isha] += 30`. The
Map is correctly defensively copied before mutation. **OK.**

(Caveat: tabular hijri can be ±1 day vs Saudi declaration — see M4. The
gating logic itself is correct.)

### V4. iOS Safari user-gesture requirement is satisfied

**File:** `lib/ui/widgets/location_first_run.dart:30-55`

`_useGps` is wired to a button's `onPressed`. `Geolocator.getCurrentPosition`
is called inside this user-gesture handler (via the `LocationService` 
wrapper). On iOS Safari this satisfies the requirement. **OK.**

### V5. Ticker is correctly cancelled in dispose

**File:** `lib/features/prayer_times/prayer_times_screen.dart:48-51`

`_ticker?.cancel()` is called in `dispose()`. **OK.**

### V6. `mounted` guards in LocationFirstRun's async callbacks

**File:** `lib/ui/widgets/location_first_run.dart:41-54`

After `await _location.getCurrent(...)`, the code does
`if (!mounted) return;` before `widget.onReady()`. Each catch block does
the same before `setState`. **OK.**

### V7. iOS webkitCompassHeading skip-declination logic

**File:** `lib/core/qibla/qibla_service.dart:96-101` (web stream).

`webkitCompassHeading` per Apple docs returns "heading in degrees of the
device from due **North**". Confirmed true-north. The code skips
declination on this path. **OK** — and contrast with C2 above where the
NATIVE iOS path **incorrectly** adds declination.

### V8. Android Chrome `360 - alpha` conversion

**File:** `lib/core/qibla/web_compass_web.dart:67-74`

W3C DeviceOrientation `alpha` is measured CCW from East in some specs;
for `deviceorientationabsolute`, alpha=0 means the device's local Y-axis
points to magnetic north. The compass heading (clockwise from north) is
`360 - alpha`. Verified consistent with multiple references and the W3C
Working Group note. **OK.**

(Note: Chromium since 2018 actually exposes alpha as
"degrees clockwise from north" already, in violation of the spec, but
this matches the formula. Either way, `360 - alpha` works.)

### V9. Great-circle Qibla formula matches §2.3

**File:** `lib/core/qibla/qibla_service.dart:41-46` →
adhan_dart `lib/src/Qibla.dart:29-41`.

The formula is the standard initial-bearing great-circle:
`atan2(sin(Δλ), cos(φ₁)·tan(φ₂) - sin(φ₁)·cos(Δλ))`. This is
algebraically equivalent to the form in RESEARCH.md §2.2 (multiply num
and den by cos(φ₂)). Spot-check via RESEARCH.md §2.3's published Karachi
bearing of 267.74°: adhan_dart returns 267.7° for Karachi. **OK.**

### V10. `LocationGate` correctly hides the gate once a manual location
exists

**File:** `lib/ui/widgets/location_first_run.dart:185-208`. If
`manualLatitude` and `manualLongitude` are both non-null, `_ready = true`
and the child is shown. Otherwise `LocationFirstRun` is shown. **OK.**

### V11. Notification timezone is set from device timezone

**File:** `lib/core/notifications/prayer_notifier.dart:24-31`. Uses
`flutter_timezone` to fetch the IANA name and sets `tz.local` accordingly.
If the device timezone is `null` (older Android emulator quirk), it falls
through silently — note that `tz.local` defaults to UTC in that case, so
scheduled times will fire at UTC. Document or fall back to a manual setting.

However, since `.reschedule(...)` is never called (see C3), this is
moot in practice today. Once C3 is fixed, double-check that `_timezoneName
!= null` on all target platforms.

---

## Summary of action items, priority order

1. **(C3)** Wire `PrayerNotifier.reschedule(...)` into `prayer_times_screen`
   after `_bootstrap` and on `AppLifecycleState.resumed`. Without this,
   notifications never fire.
2. **(C1, H4)** Replace `magnetic_declination.dart` with the WMM 2025
   spherical-harmonic model (or use `geomag` Dart package, or platform
   native APIs).
3. **(C2)** On native iOS, skip declination addition because
   `flutter_compass_v2` already returns trueHeading. Branch in
   `qibla_service.compassStream` by `defaultTargetPlatform`.
4. **(C4)** Audit prayer-day rollover for users at extreme west longitudes
   late at night; if confirmed problematic, derive `date` for adhan_dart
   from `now.toLocal().day` more carefully, or compute three consecutive
   day's prayer times and select the right one based on local time.
5. **(H3)** Fix region_detector box ordering: Dubai/UAE before Saudi+GCC,
   Tunisia before Algeria, Cyprus reconsidered.
6. **(H1, H2)** Add HighLatitudeRule and PolarCircleResolution to
   Settings, persist, and pass through.
7. **(M1, M3, M4, M5, M6)** UX polish.

Items C1 + C2 + C3 + the H3-Dubai bug must be fixed before any Play
Store / App Store release.
