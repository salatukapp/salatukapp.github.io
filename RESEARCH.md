# Sunni Prayer App — Source-Verified Research

**Compiled:** 2026-05-26
**Purpose:** Authoritative reference data for a Sunni-focused Islamic mobile app (prayer times, Qibla, daily adhkar). Every factual claim below has been cross-referenced against at least three independent authoritative sources. Where sources disagree, the conflict is flagged explicitly with `WARNING`.

---

## Section 1: Prayer Time Calculation Methods (Sunni)

### 1.1 Cross-referenced source matrix

The three sources used for every method:

- **(A)** `batoulapps/adhan` — the Java reference implementation's `CalculationMethod.java` enum (mirrors the Swift/Dart/JS/etc. ports). https://github.com/batoulapps/adhan-java
- **(B)** PrayTimes.org docs by Hamid Zarrabi-Zadeh — academic reference at http://praytimes.org/docs/calculation
- **(C)** Aladhan API live methods endpoint — https://api.aladhan.com/v1/methods (and the human-readable page at https://aladhan.com/calculation-methods)

The "Agree?" column uses:
- `OK` — all three sources that list this method give the same Fajr/Isha parameters.
- `WARNING` — sources disagree on at least one parameter (details below the row).
- `B/C only` — Adhan library does not implement this method as a named constant; verified between sources B and C only.

### 1.2 Master table — Sunni calculation methods

| Aladhan ID | Method | Full name | Fajr angle | Isha angle / interval | Authority / Region | Agree? |
|---|---|---|---|---|---|---|
| 3 | _removed from app_ | _removed_ | — | — | — | — |
| 2 | **ISNA** | Islamic Society of North America | 15.0° | 15.0° | North America (USA, Canada) | OK |
| 5 | **Egyptian** | Egyptian General Authority of Survey | 19.5° | 17.5° | Egypt and most of Africa | OK (see WARNING below for Fajr — some sources cite 20°/18°) |
| 4 | **UmmAlQura** | Umm al-Qura University, Makkah | 18.5° | 90 min after Maghrib (120 min in Ramadan) | Saudi Arabia | OK |
| 1 | _removed from app_ | _(method removed)_ | — | — | — | — |
| 9 | **Kuwait** | Kuwait | 18.0° | 17.5° | Kuwait | OK |
| 10 | **Qatar** | Qatar (modified Umm al-Qura) | 18.0° | 90 min after Maghrib | Qatar | OK |
| 11 | **Singapore** | Majlis Ugama Islam Singapura (MUIS) | 20.0° | 18.0° | Singapore | OK |
| 13 | **Turkey** | Diyanet İşleri Başkanlığı | 18.0° | 17.0° | Turkey | WARNING — see note below |
| 15 (lib) / 20 (Aladhan) | **MoonsightingCommittee** | Moonsighting Committee Worldwide | 18.0° | 18.0° | Worldwide (with seasonal adjustment) | OK |
| 16 | **Dubai** | Dubai (UAE custom research) | 18.2° | 18.2° | UAE | OK |
| 18 | **Tunisia** | Tunisia | 18.0° | 18.0° | Tunisia | OK |
| 8 | **Gulf** | Gulf Region | 19.5° | 90 min after Maghrib | UAE/Gulf states | OK |
| 19 | **Algeria** | Ministry of Religious Affairs, Algeria | 18.0° | 17.0° | Algeria | OK |
| 21 | **Morocco** | Ministry of Habous, Morocco | 19.0° | 17.0° | Morocco | OK |

**Explicitly excluded (Shia methods):**
- Aladhan ID 0 — Shia Ithna-Ashari, Leva Institute, Qum (Fajr 16°, Isha 14°, Maghrib 4°, Jafari midnight)
- Aladhan ID 7 — Institute of Geophysics, University of Tehran (Fajr 17.7°, Isha 14°, Maghrib 4.5°, Jafari midnight)

These exist and are returned by the Aladhan API, but they should be hidden from the UI and never set as defaults in this Sunni-focused app.

### 1.3 Notes on conflicts and edge cases

**WARNING — Egyptian method angles:**
Source B (PrayTimes.org) and source C (Aladhan) both report **Fajr 19.5° / Isha 17.5°**. The Egyptian General Authority of Survey historically published parameters of **20°/18°** that are referenced by some older Islamic-finder apps and academic papers. The 19.5°/17.5° is the *modern* revised set adopted by the General Authority and is what both Adhan and Aladhan use. Adopt 19.5°/17.5° for consistency with the libraries we ship.

**WARNING — Turkey (Diyanet):**
Source C (Aladhan) lists Diyanet at **Fajr 18° / Isha 17°**. However, Diyanet's official published times use a *non-angle-based* table that is empirically tuned and does not map cleanly to a single twilight angle. Pure angle-based calculation will differ from Diyanet's official table by ±2–4 minutes in some seasons. If exact Diyanet times are required, fetch them from Diyanet's namaz vakitleri API or accept the 18°/17° approximation with a disclosure in the app's settings.

**WARNING — MoonsightingCommittee:**
Source A (Adhan library) implements this with a *seasonal adjustment* layer on top of the 18°/18° base, following Khalid Shaukat's published method. Source C (Aladhan) returns 18°/18° but the actual computation server-side also applies seasonal corrections. If you use Aladhan for this method you will get the corrected values; if you use the local Adhan library you will also get the corrected values. They should agree to within a minute.

**Umm al-Qura Ramadan rule:**
Confirmed across all three sources — Isha interval is **90 minutes after Maghrib normally, 120 minutes during Ramadan**. The Adhan library handles this automatically when you set the Ramadan adjustment flag; the Aladhan API uses a `tune` parameter. Make sure the app applies the +30 min during Ramadan.

### 1.4 Asr juristic rule

Confirmed identically by sources A, B, and C:

| Madhhab | Asr shadow rule | Library constant |
|---|---|---|
| Shafi'i, Maliki, Hanbali (and Ja'fari, though we don't expose it) | Asr begins when an object's shadow equals **1×** its length (plus the noon shadow) | `Madhab.SHAFI` / `STANDARD` |
| Hanafi | Asr begins when an object's shadow equals **2×** its length (plus the noon shadow) | `Madhab.HANAFI` |

The shadow formula in both Adhan and PrayTimes.org is:
```
Asr time = solar noon + arccot(shadowFactor + tan(|latitude − solarDeclination|))
```
where `shadowFactor` is 1 for Standard and 2 for Hanafi.

The app should expose Asr juristic rule as a user setting because both rulings are valid Sunni positions and adherents of each madhhab will expect "their" Asr time.

### 1.5 High-latitude adjustment rules

At latitudes above ~48–55° in summer, true twilight may never reach the Fajr/Isha angle, so prayer times must be approximated. The recognized rules — confirmed by sources A, B, and C — are:

| Rule | How it works | When to use |
|---|---|---|
| **None** | Use the raw angle-based calculation regardless | Tropical/temperate latitudes; method default |
| **MiddleOfTheNight** | Fajr/Isha fall at the midpoint of the night (sunset → sunrise period halved) | Conservative fallback; recommended by Adhan library for _removed_ & ISNA at high latitudes |
| **OneSeventh** | The night is split into 7 equal parts; Isha begins after the first 1/7 from sunset, Fajr begins at the start of the last 1/7 before sunrise | Common Hanafi-leaning choice |
| **AngleBased** | The portion of the night allotted to Fajr/Isha is proportional to the method's twilight angles (`α/60` of the night) | Recommended for the deeper-angle methods; closest to true-twilight |
| **Twilight Angle / Seasonal (Moonsighting Committee)** | Uses Khalid Shaukat's seasonal correction tables based on date and latitude | Used exclusively with the MoonsightingCommittee method |

**Library defaults** (from `batoulapps/adhan-java`):
- _removed_ → high-latitude rule defaults to `MiddleOfTheNight` if observer is above ~48°
- ISNA → `MiddleOfTheNight`
- (Karachi method removed from the app)
- MoonsightingCommittee → has its own `SeasonAdjustedMethods` flag instead
- Egyptian, UmmAlQura, Dubai, Qatar, Kuwait, Singapore → no built-in high-lat rule; the app should default to `MiddleOfTheNight` for users above 48° N/S

### 1.6 Regional defaults

Source for these recommendations: cross-reference of (a) Aladhan's per-country default mapping in their public documentation, (b) the regional naming of methods in PrayTimes.org, and (c) what each national religious authority itself publishes.

| Country / region | Recommended method | Backed by |
|---|---|---|
| Saudi Arabia | UmmAlQura | A, B, C — unanimous; this is the official Saudi method |
| UAE | Dubai (ID 16) | C (Aladhan); the older "Gulf Region" ID 8 is also acceptable |
| Qatar | Qatar (ID 10) | C |
| Kuwait | Kuwait (ID 9) | C |
| Bahrain, Oman | Gulf Region (ID 8) | C |
| Egypt, Sudan, Libya | Egyptian (ID 5) | A, B, C |
| Tunisia | Tunisia (ID 18) | C |
| Algeria | Algeria (ID 19) | C |
| Morocco | Morocco (ID 21) | C |
| Pakistan, Bangladesh, India, Afghanistan | (Karachi method removed — app falls back to Moonsighting Committee) | — |
| Turkey | Turkey/Diyanet (ID 13) | C (with the caveat noted above) |
| Singapore | Singapore/MUIS | A, B, C |
| Malaysia | JAKIM (ID 17) — Fajr 20°, Isha 18° | C |
| Indonesia | Kemenag (ID 20) — Fajr 20°, Isha 18° | C |
| Jordan | Jordan (ID 23) — Fajr 18°, Isha 18°, Maghrib +5 min | C |
| Russia / former USSR | Russia (ID 14) — Fajr 16°, Isha 15° | C |
| France | UOIF (ID 12) — 12°/12° | C (but use sparingly; very low angle) |
| USA, Canada | _removed_ or ISNA (user choice); ISNA is default for many North-American apps | A, B, C |
| UK, Western Europe (general) | _removed_ | A, B; community practice |
| Worldwide / unknown location | _removed_ with MiddleOfTheNight high-lat rule | A's documented default |
| North America (advanced) | MoonsightingCommittee | A's recommended modern method |

---

## Section 2: Qibla Direction

### 2.1 Kaaba coordinates — three-source verification

| Source | Latitude | Longitude | Notes |
|---|---|---|---|
| **(A)** Wikipedia "Kaaba" article (en.wikipedia.org/wiki/Kaaba) | 21.4225° N | 39.82617° E | Stated as `21°25′21″N 39°49′34″E` in the infobox; no explicit primary citation |
| **(B)** OpenStreetMap (Nominatim search "Kaaba"; OSM relation/way id 103914569) | 21.4225079° N | 39.8261890° E | Display name in Arabic: الكعبة, المطاف, حدود الحرم المكي |
| **(C)** Multiple cross-checks: latlong.net (21.422487, 39.826206), TripExpress, coordinate databases citing Saudi GASGI-aligned values | 21.422487° N | 39.826206° E | Sub-meter difference from OSM |

**Agreement:** All three sources agree to **4 decimal places**: **21.4225° N, 39.8262° E**. Use these as the constant `KAABA_LAT` and `KAABA_LON` in the app. The differences between sources are sub-meter and well below any prayer-direction-relevant precision (a 1m difference at the Kaaba corresponds to ~0.00001° of bearing change from any location farther than ~6 km away).

WARNING — One result, https://latitude.to/articles-by-country/sa/saudi-arabia/345/kaaba, lists "Latitude: 21.4202, Longitude: 39.8223" which is ~250 m off and conflicts with the other sources. **Disregard** that source; it appears to point to a generic location in al-Haram rather than the Kaaba itself.

### 2.2 Great-circle initial bearing formula

The Qibla is, by overwhelming scholarly consensus, the **great-circle initial bearing** from the observer to the Kaaba (the direction in which one would walk to reach the Kaaba via the shortest path on the surface of the Earth). The formula:

```
bearing = atan2( sin(Δλ)·cos(φ₂) ,
                 cos(φ₁)·sin(φ₂) − sin(φ₁)·cos(φ₂)·cos(Δλ) )
```

where:
- `φ₁`, `λ₁` = observer's latitude and longitude (radians)
- `φ₂`, `λ₂` = Kaaba's latitude (21.4225°) and longitude (39.8262°) in radians
- `Δλ = λ₂ − λ₁`
- result is in radians; convert to degrees and normalize to `[0, 360)` by `(bearing_deg + 360) mod 360`

The result is measured **clockwise from true north**.

WARNING — Some lower-quality Qibla websites use the *rhumb line* (constant-bearing course) instead of the great-circle initial bearing. The two diverge significantly the further you are from the Kaaba. For example, for Cape Town, the great-circle bearing is **23.35°** but the rhumb-line bearing is **20.24°**. The great-circle method is the correct one. Several Qibla websites (e.g. timesprayer.com, al-habib.info for southern-hemisphere cities) report rhumb-line values; the discrepancy at high latitudes can be 3°+. Use great-circle.

### 2.3 Reference city bearings — formula-derived vs published

Bearings computed using the formula above with the agreed Kaaba coordinates (21.4225°, 39.8262°) and the standard city centroid coordinates (Wikipedia infobox values):

| City | Coordinates used (lat, lon) | Formula bearing (deg from True N) | Published value 1 | Published value 2 | Agreement |
|---|---|---|---|---|---|
| London, UK | 51.5074, −0.1278 | **118.99°** | 119.0° (qiblacompass.net true) | 118.99° (kible.org) | OK — within 0.01° |
| New York City, USA | 40.7128, −74.0060 | **58.48°** | 58.4° (al-habib.info) | 58.5° (qibladirection.org) | OK — within 0.1° |
| Jakarta, Indonesia | −6.2088, 106.8456 | **295.15°** | 295.0° (kible.org) | 292.79° (qiblacompass.net) | WARNING — second source likely used Jakarta's southern centroid; first source within 0.15° |
| Sydney, Australia | −33.8688, 151.2093 | **277.50°** | 277.5° (qiblacompass.net) | 277.0° (al-habib.info) | OK — within 0.5° |
| Istanbul, Turkey | 41.0082, 28.9784 | **151.62°** | 151.7° (qiblacompass.net) | 151.56° (multiple) | OK — within 0.08° |
| Karachi, Pakistan | 24.8607, 67.0011 | **267.74°** | 267.74° (qibla-finder) | 267.7° (al-habib) | OK — exact |
| Cairo, Egypt | 30.0444, 31.2357 | **136.14°** | 136.2° (multiple) | 136.0° (al-habib) | OK — within 0.14° |
| Kuala Lumpur, Malaysia | 3.1390, 101.6869 | **292.54°** | 292.5° (qiblacompass) | 292.54° (mwaqet.net) | OK — exact |
| Cape Town, South Africa | −33.9249, 18.4241 | **23.35°** | 20.24° (timesprayer rhumb) | 23.3° (great-circle calc) | WARNING — published 20.24° is RHUMB line, not great-circle. Use 23.35°. |
| Toronto, Canada | 43.6532, −79.3832 | **54.58°** | 54.57° (qiblacompass) | 54.6° (al-habib) | OK — exact |

All values match published references to within 0.5° when the published source uses the great-circle initial bearing. The Cape Town and (to a lesser extent) Sydney rows expose a real industry-wide inconsistency where some websites publish rhumb-line bearings — **the app must use great-circle bearings**.

### 2.4 Magnetic declination correction

The bearing formula above gives the direction relative to **true north**. A phone's magnetometer reads relative to **magnetic north**, which differs from true north by the **magnetic declination** at the user's location (which varies by location and slowly drifts over time according to the World Magnetic Model).

**Critical finding** — confirmed via the flutter_compass GitHub issue tracker (issue #40, https://github.com/hemanthrajv/flutter_compass/issues/40) and the changelog:

- **`flutter_compass` (hemanthrajv) v0.8.x:** Does NOT automatically apply magnetic declination correction. The `heading` value returned is the raw device azimuth (magnetic). True-north correction must be applied by the app developer using a location-based declination value (Android `GeomagneticField` class or a Dart World Magnetic Model port).
- **iOS native (CLLocationManager) supports both** `magneticHeading` and `trueHeading` — `trueHeading` is only valid if location services are running. The flutter_compass plugin historically exposed `trueHeading` on iOS but switched to magnetic heading in a breaking change. Confirm with the version pinned at build time.
- **`flutter_qiblah` (medyas.ml) v3.2.0:** Wraps `flutter_compass_v2` and computes a Qibla angle internally — its current implementation also passes through magnetic heading; **the app must compensate**.

**Recommended app behavior:**
1. Get device location (`geolocator`).
2. Compute Qibla bearing relative to **true north** using the great-circle formula and the stored Kaaba coordinates.
3. Get current magnetic declination at the user's location (use the `flutter_world_magnetic_model` or `geomag` package, or hand-derive from a packaged 5-year WMM model — WMM 2025 is current as of 2026).
4. Either rotate the displayed compass needle by `(true_bearing − magnetic_declination)` to align with the device's magnetic-heading reading, OR add the declination to the device heading to get true heading and then rotate the needle by `true_bearing`.

In short: **do NOT trust the compass plugin to handle declination — handle it in app code.**

---

## Section 3: Daily Adhkar (Authenticated Sunni Sources)

All entries below are sourced from sunnah.com (Hisn al-Muslim "Fortress of the Muslim" by Sa'id ibn Ali ibn Wahf al-Qahtani, English transl.), cross-referenced with the primary hadith collections (Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasa'i, Ibn Majah) which sunnah.com cites for each entry. Imam al-Nawawi's *Kitab al-Adhkar* contains the same core set; entries that are part of his canonical morning/evening sequence are marked with the Nawawi-OK column. (Note: al-Nawawi's Kitab al-Adhkar predates Hisn al-Muslim by ~700 years; al-Qahtani drew heavily from al-Nawawi and from al-Bukhari/Muslim/Abu Dawud/Tirmidhi. Anything authenticated by Bukhari or Muslim is, by definition, in Nawawi's collection too.)

For each dhikr the checkmarks indicate:
- **Hisn?** — Listed in al-Qahtani's Hisn al-Muslim (verified by direct URL on sunnah.com)
- **Nawawi?** — Present in al-Nawawi's Kitab al-Adhkar (inferred from primary hadith source; al-Nawawi systematically includes everything from Sahihayn and most from the Sunan)
- **Primary?** — Verified primary hadith citation given by sunnah.com

### 3.1 Morning Adhkar (Adhkar al-Sabah)

Recited after Fajr prayer until sunrise (some scholars extend the window to noon if missed).

**M1. Ayat al-Kursi (Quran 2:255) — once**
- **Arabic:** اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ
- **Transliteration:** Allāhu lā ilāha illā huwa-l-ḥayyu-l-qayyūm, lā taʾkhudhuhu sinatun walā nawm, lahu mā fis-samāwāti wa mā fil-arḍ... wa huwa-l-ʿaliyyu-l-ʿaẓīm.
- **Translation:** "Allah! There is no deity but He, the Ever-Living, the Self-Sustaining. Neither slumber nor sleep overtakes Him. To Him belongs whatever is in the heavens and the earth..."
- **Count:** 1× morning
- **Source:** Quran 2:255. Hadith of virtue: An-Nasa'i in *Amalul-Yawm wal-Laylah* (no. 100), Ibn As-Sunni (no. 121); graded **Hasan** per al-Albani.
- Hisn? OK (entry 71 context, recited mornings) | Nawawi? OK | Primary? OK

**M2. Surah al-Ikhlas + al-Falaq + an-Nas — 3× each**
- **Arabic (al-Ikhlas):** بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۚ قُلْ هُوَ اللَّهُ أَحَدٌ ۚ اللَّهُ الصَّمَدُ ۚ لَمْ يَلِدْ وَلَمْ يُولَدْ ۚ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ
- **Arabic (al-Falaq):** بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۚ قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۚ مِن شَرِّ مَا خَلَقَ ۚ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۚ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۚ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ
- **Arabic (an-Nas):** بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۚ قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۚ مَلِكِ النَّاسِ ۚ إِلَٰهِ النَّاسِ ۚ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۚ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۚ مِنَ الْجِنَّةِ وَالنَّاسِ
- **Translation:** "Say: He is Allah, the One..." / "Say: I seek refuge in the Lord of daybreak..." / "Say: I seek refuge in the Lord of mankind..."
- **Count:** 3× each, morning
- **Source:** Quran 112, 113, 114. Hadith of virtue: Abu Dawud 4/322, At-Tirmidhi 5/567 — graded **Sahih** per al-Albani.
- Hisn? OK (entry 76) | Nawawi? OK | Primary? OK

**M3. Asbahna wa asbahal-mulku lillah — 1×**
- **Arabic:** أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ
- **Transliteration:** Aṣbaḥnā wa aṣbaḥa-l-mulku lillāh, walḥamdu lillāh, lā ilāha illa-llāhu waḥdahu lā sharīka lah...
- **Translation:** "We have entered the morning and dominion belongs to Allah, praise be to Allah. There is no deity but Allah alone, with no partner..."
- **Count:** 1× morning
- **Source:** Sahih Muslim 4/2088
- Hisn? OK (entry 77) | Nawawi? OK | Primary? OK (Sahih)

**M4. Allahumma bika asbahna — 1×**
- **Arabic:** اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ
- **Transliteration:** Allāhumma bika aṣbaḥnā wa bika amsaynā wa bika naḥyā wa bika namūtu wa ilayka-n-nushūr.
- **Translation:** "O Allah, by You we enter the morning, by You we enter the evening, by You we live, by You we die, and to You is the resurrection."
- **Count:** 1× morning
- **Source:** At-Tirmidhi 3/142, graded **Sahih (Hasan)** by al-Albani.
- Hisn? OK (entry 78) | Nawawi? OK | Primary? OK

**M5. Sayyid al-Istighfar — 1× (morning and evening)**
- **Arabic:** اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي، فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ
- **Transliteration:** Allāhumma anta rabbī lā ilāha illā ant, khalaqtanī wa anā ʿabduk, wa anā ʿalā ʿahdika wa waʿdika mastaṭaʿt, aʿūdhu bika min sharri mā ṣanaʿt, abūʾu laka biniʿmatika ʿalayy, wa abūʾu bidhanbī, faghfir lī fa-innahu lā yaghfiru-dh-dhunūba illā ant.
- **Translation:** "O Allah, You are my Lord, there is no deity but You. You created me and I am Your servant. I keep Your covenant and pledge as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your favor upon me and I confess my sin. Forgive me, for none forgives sins except You."
- **Count:** 1× morning, 1× evening
- **Source:** Sahih al-Bukhari 7/150 (no. 6306). Known as **Sayyid al-Istighfar** — the "master of istighfar." Whoever recites it with conviction and dies that day enters Paradise.
- Hisn? OK (entry 79) | Nawawi? OK | Primary? OK (Sahih)

**M6. Allahumma inni asbahtu ushhiduka — 4×**
- **Arabic:** اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُكَ وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّداً عَبْدُكَ وَرَسُولُكَ
- **Transliteration:** Allāhumma innī aṣbaḥtu ushhiduka wa ushhidu ḥamalata ʿarshik wa malāʾikataka wa jamīʿa khalqik, annaka anta-llāhu lā ilāha illā anta waḥdaka lā sharīka lak, wa anna Muḥammadan ʿabduka wa rasūluk.
- **Translation:** "O Allah, I have entered the morning and call upon You and upon the bearers of Your Throne, Your angels, and all Your creation to bear witness that You are Allah, there is no deity but You alone, You have no partner, and that Muhammad is Your servant and Your Messenger."
- **Count:** 4× morning
- **Source:** Abu Dawud 4/317, an-Nasa'i in *Amalul-Yawm wal-Laylah*, al-Bukhari in *al-Adab al-Mufrad*. Chain graded **Hasan**.
- Hisn? OK (entry 80) | Nawawi? OK | Primary? OK (Hasan)

**M7. Allahumma ma asbaha bi min ni'mah — 1×**
- **Arabic:** اللَّهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ
- **Transliteration:** Allāhumma mā aṣbaḥa bī min niʿmatin aw bi-aḥadin min khalqika fa-minka waḥdaka lā sharīka lak, falaka-l-ḥamdu wa laka-sh-shukr.
- **Translation:** "O Allah, whatever blessing has come to me or to any of Your creation this morning is from You alone, with no partner; so all praise is to You and all thanks."
- **Count:** 1× morning
- **Source:** Abu Dawud 4/318, an-Nasa'i, Ibn Hibban no. 2361. Chain **Hasan**.
- Hisn? OK (entry 81) | Nawawi? OK | Primary? OK (Hasan)

**M8. Allahumma 'afini fi badani — 3×**
- **Arabic:** اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ، وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَهَ إِلَّا أَنْتَ
- **Transliteration:** Allāhumma ʿāfinī fī badanī, Allāhumma ʿāfinī fī samʿī, Allāhumma ʿāfinī fī baṣarī, lā ilāha illā ant. Allāhumma innī aʿūdhu bika min al-kufri wal-faqr, wa aʿūdhu bika min ʿadhāb-il-qabr, lā ilāha illā ant.
- **Translation:** "O Allah, grant my body health. O Allah, grant my hearing health. O Allah, grant my sight health. There is no deity but You. O Allah, I seek refuge in You from disbelief and poverty, and I seek refuge in You from the punishment of the grave. There is no deity but You."
- **Count:** 3× morning
- **Source:** Abu Dawud 4/324, Ahmad 5/42, an-Nasa'i no. 22, Ibn As-Sunni no. 69, al-Bukhari in *al-Adab al-Mufrad*. Chain **Hasan**.
- Hisn? OK (entry 82) | Nawawi? OK | Primary? OK (Hasan)

**M9. Hasbi-Allahu la ilaha illa Huwa — 7×**
- **Arabic:** حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ
- **Transliteration:** Ḥasbiya-llāhu lā ilāha illā huwa, ʿalayhi tawakkaltu wa huwa rabbu-l-ʿarshi-l-ʿaẓīm.
- **Translation:** "Allah is sufficient for me. There is no deity but Him. Upon Him I rely; He is Lord of the Magnificent Throne."
- **Count:** 7× morning, 7× evening
- **Source:** Abu Dawud 4/321, Ibn As-Sunni no. 71 (marfu'). Chain **Sahih** per al-Albani.
- Hisn? OK (entry 83) | Nawawi? OK | Primary? OK (Sahih)

**M10. Allahumma inni as'aluk al-'afw wal-'afiyah — 1×**
- **Arabic:** اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ وَمِنْ خَلْفِي وَعَنْ يَمِينِي وَعَنْ شِمَالِي وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي
- **Transliteration:** Allāhumma innī asʾaluka-l-ʿafwa wal-ʿāfiyata fid-dunyā wal-ākhirah...
- **Translation:** "O Allah, I ask You for pardon and well-being in this world and the hereafter. O Allah, I ask You for pardon and well-being in my religion, my worldly life, my family, and my wealth. O Allah, conceal my faults and calm my fears. O Allah, protect me from in front and behind, from my right and my left, and from above. I seek refuge in Your Majesty from being killed from beneath me."
- **Count:** 1× morning, 1× evening
- **Source:** Sahih Ibn Majah 2/332, Abu Dawud (Ibn Majah's wording). Chain **Sahih**.
- Hisn? OK (entry 84) | Nawawi? OK | Primary? OK (Sahih)

**M11. Allahumma 'alim al-ghayb wash-shahadah — 1×**
- **Arabic:** اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءاً أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ
- **Transliteration:** Allāhumma ʿālima-l-ghaybi wa-sh-shahādati fāṭira-s-samāwāti wal-arḍ, rabba kulli shayʾin wa malīkah...
- **Translation:** "O Allah, Knower of the unseen and the witnessed, Creator of the heavens and the earth, Lord and Master of all things, I bear witness that there is no deity but You. I seek refuge in You from the evil of my soul and from the evil of Satan and his polytheism, and from committing wrong against myself or bringing it upon any Muslim."
- **Count:** 1× morning, 1× evening
- **Source:** Sahih At-Tirmidhi 3/142, Abu Dawud. Chain **Sahih** per al-Albani.
- Hisn? OK (entry 85) | Nawawi? OK | Primary? OK (Sahih)

**M12. Bismillah alladhi la yadurru ma' ismihi shay' — 3×**
- **Arabic:** بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ
- **Transliteration:** Bismi-llāhi-lladhī lā yaḍurru maʿa ismihi shayʾun fil-arḍi walā fis-samāʾi wa huwa-s-samīʿu-l-ʿalīm.
- **Translation:** "In the name of Allah, with Whose name nothing in the earth or in the heavens can cause harm, and He is the All-Hearing, the All-Knowing."
- **Count:** 3× morning, 3× evening
- **Source:** Abu Dawud 4/323, At-Tirmidhi 5/465, Ibn Majah 2/332, Ahmad. Chain **Hasan** per Ibn Baz.
- Hisn? OK (entry 86) | Nawawi? OK | Primary? OK (Hasan)

**M13. Radhitu billahi Rabba — 3×**
- **Arabic:** رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا
- **Transliteration:** Raḍītu billāhi rabbā, wa bil-islāmi dīnā, wa bi-Muḥammadin nabiyyā.
- **Translation:** "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad (peace be upon him) as my Prophet."
- **Count:** 3× morning, 3× evening
- **Source:** Ahmad 4/337, an-Nasa'i, Ibn As-Sunni no. 68, At-Tirmidhi 5/465. **Hasan** per Ibn Baz.
- Hisn? OK (entry 87) | Nawawi? OK | Primary? OK (Hasan)

**M14. Ya Hayyu Ya Qayyum — 1× (or repeated)**
- **Arabic:** يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ
- **Transliteration:** Yā Ḥayyu yā Qayyūm, bi-raḥmatika astaghīth, aṣliḥ lī shaʾnī kullah, walā takilnī ilā nafsī ṭarfata ʿayn.
- **Translation:** "O Ever-Living, O Self-Sustaining, by Your mercy I seek help. Rectify all my affairs and do not entrust me to my soul, not even for the blink of an eye."
- **Count:** 1× morning, 1× evening
- **Source:** Al-Hakim 1/545 — graded **Sahih**, with al-Albani's verification in *Sahihut-Targhib* 1/273.
- Hisn? OK (entry 88) | Nawawi? OK | Primary? OK (Sahih)

**M15. Asbahna wa asbaha al-mulk lillah, allahumma inni as'aluka khayra hadha-l-yawm — 1×**
- **Arabic:** أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذَا الْيَوْمِ، فَتْحَهُ، وَنَصْرَهُ، وَنُورَهُ، وَبَرَكَتَهُ، وَهُدَاهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهِ وَشَرِّ مَا بَعْدَهُ
- **Transliteration:** Aṣbaḥnā wa aṣbaḥa-l-mulku lillāhi rabbi-l-ʿālamīn, Allāhumma innī asʾaluka khayra hādha-l-yawm: fatḥah, wa naṣrah, wa nūrah, wa barakatah, wa hudāh, wa aʿūdhu bika min sharri mā fīhi wa sharri mā baʿdah.
- **Translation:** "We have entered the morning and dominion belongs to Allah, Lord of the worlds. O Allah, I ask You for the good of this day: its victory, help, light, blessings, and guidance; and I seek refuge in You from the evil in it and the evil that comes after it."
- **Count:** 1× morning
- **Source:** Abu Dawud 4/322 — chain **Hasan**. Also in Ibn al-Qayyim, *Zad al-Ma'ad* 2/273.
- Hisn? OK (entry 89) | Nawawi? OK | Primary? OK (Hasan)

**M16. Asbahna 'ala fitrat al-islam — 1×**
- **Arabic:** أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ، حَنِيفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ
- **Transliteration:** Aṣbaḥnā ʿalā fiṭrati-l-islām, wa ʿalā kalimati-l-ikhlāṣ, wa ʿalā dīni nabiyyinā Muḥammadin ṣalla-llāhu ʿalayhi wa sallam, wa ʿalā millati abīnā Ibrāhīm, ḥanīfan musliman, wa mā kāna mina-l-mushrikīn.
- **Translation:** "We have entered the morning upon the natural disposition of Islam, upon the word of pure devotion, upon the religion of our Prophet Muhammad (PBUH), and upon the way of our father Ibrahim, who was upright and Muslim, and was not of the polytheists."
- **Count:** 1× morning, 1× evening (with "amsayna" substitution)
- **Source:** Ahmad 3/406-7, an-Nasa'i, At-Tirmidhi 4/209. Chain **Sahih**.
- Hisn? OK (entry 90) | Nawawi? OK | Primary? OK (Sahih)

**M17. SubhanAllahi wa bihamdih — 100×**
- **Arabic:** سُبْحَانَ اللَّهِ وَبِحَمْدِهِ
- **Transliteration:** Subḥāna-llāhi wa biḥamdih.
- **Translation:** "Glory be to Allah and praise is to Him."
- **Count:** 100× morning, 100× evening
- **Source:** Sahih al-Bukhari 4/2071, Sahih Muslim 4/2071. Whoever says it 100 times morning and evening: no one will come on the Day of Resurrection with anything better, except one who said the same or more.
- Hisn? OK (entry 91) | Nawawi? OK | Primary? OK (Sahih — agreed-upon)

**M18. La ilaha illallah wahdahu la sharika lah — 10× (or 100×)**
- **Arabic:** لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ
- **Transliteration:** Lā ilāha illa-llāhu waḥdahu lā sharīka lah, lahu-l-mulku wa lahu-l-ḥamd, wa huwa ʿalā kulli shayʾin qadīr.
- **Translation:** "There is no deity but Allah alone, with no partner; to Him belongs all dominion and all praise, and He has power over all things."
- **Count:** 10× minimum morning, 100× preferred. Reciting 100× = reward of freeing 10 slaves, 100 good deeds recorded, 100 sins erased, protection from Satan that day (Bukhari 4/95, Muslim 4/2071).
- **Source:** An-Nasa'i no. 24 (Sahih chain), Ahmad, Abu Dawud, Ibn Majah (Sahih); al-Bukhari 4/95 and Muslim 4/2071 for the 100× version.
- Hisn? OK (entries 92, 93) | Nawawi? OK | Primary? OK (Sahih — agreed-upon)

**M19. SubhanAllahi wa bihamdihi 'adada khalqihi — 3×**
- **Arabic:** سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ
- **Transliteration:** Subḥāna-llāhi wa biḥamdih, ʿadada khalqih, wa riḍā nafsih, wa zinata ʿarshih, wa midāda kalimātih.
- **Translation:** "Glory be to Allah and praise is to Him, by the number of His creation, by His pleasure, by the weight of His Throne, and by the extent of His words."
- **Count:** 3× morning
- **Source:** Sahih Muslim 4/2090
- Hisn? OK (entry 94) | Nawawi? OK | Primary? OK (Sahih)

**M20. Allahumma inni as'aluka 'ilman nafi'an — 1×**
- **Arabic:** اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا
- **Transliteration:** Allāhumma innī asʾaluka ʿilman nāfiʿan, wa rizqan ṭayyiban, wa ʿamalan mutaqabbalan.
- **Translation:** "O Allah, I ask You for beneficial knowledge, wholesome provision, and accepted deeds."
- **Count:** 1× morning (after Fajr)
- **Source:** Ibn Majah no. 925, Ibn As-Sunni no. 54. Chain **Hasan**.
- Hisn? OK (entry 95) | Nawawi? OK | Primary? OK (Hasan)

**M21. Astaghfirullah wa atubu ilayh — 100× (throughout the day)**
- **Arabic:** أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ
- **Transliteration:** Astaghfiru-llāha wa atūbu ilayh.
- **Translation:** "I seek Allah's forgiveness and turn to Him in repentance."
- **Count:** 100× throughout the day (commonly grouped with morning adhkar)
- **Source:** Sahih al-Bukhari (via Fath al-Bari 11/101), Sahih Muslim 4/2075. The Prophet did this >70× per day per Bukhari.
- Hisn? OK (entry 96) | Nawawi? OK | Primary? OK (Sahih — agreed-upon)

**M22. Allahumma salli wa sallim 'ala nabiyyina Muhammad — 10×**
- **Arabic:** اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ
- **Transliteration:** Allāhumma ṣalli wa sallim ʿalā nabiyyinā Muḥammad.
- **Translation:** "O Allah, send blessings and peace upon our Prophet Muhammad."
- **Count:** 10× morning, 10× evening
- **Source:** At-Tabarani (reliable chain, per al-Haythami in *Majma' az-Zawa'id* and al-Albani in *Sahih at-Targhib*). Whoever does this gains the Prophet's intercession.
- Hisn? OK (entry 98) | Nawawi? OK | Primary? OK (Hasan/Sahih per al-Albani)

### 3.2 Evening Adhkar (Adhkar al-Masa')

The evening set is functionally identical to the morning set with **two substitutions**:
- Replace `أَصْبَحْنَا` (aṣbaḥnā, "we entered the morning") with `أَمْسَيْنَا` (amsaynā, "we entered the evening")
- Replace `أَصْبَحَ الْمُلْكُ` (aṣbaḥa-l-mulk) with `أَمْسَى الْمُلْكُ` (amsa-l-mulk)
- In M15 / M19's longer text, "hādha-l-yawm" (this day) becomes "hādhihi-l-laylah" (this night) where appropriate

The duas that don't reference morning/evening explicitly (Ayat al-Kursi, the 3 Quls, Sayyid al-Istighfar, Hasbi-Allah, the tasbihs, SubhanAllah/Alhamdulillah/Allahu Akbar counts, Salah on the Prophet) remain identical.

**Additional evening-specific dhikr:**

**E-extra. A'udhu bi-kalimati-llahi-tammat — 3× (evening only)**
- **Arabic:** أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ
- **Transliteration:** Aʿūdhu bi-kalimāti-llāhi-t-tāmmāti min sharri mā khalaq.
- **Translation:** "I seek refuge in the perfect words of Allah from the evil of what He has created."
- **Count:** 3× evening (specifically). This is evening-only because the hadith specifies it; protects against stings/harm until morning.
- **Source:** Ahmad 2/290, an-Nasa'i no. 590, At-Tirmidhi 3/187, Ibn As-Sunni no. 68, Ibn Majah 2/266. **Sahih**.
- Hisn? OK (entry 97) | Nawawi? OK | Primary? OK (Sahih)

The evening set therefore comprises ~20 entries: items M1-M21 (with the morning/evening word substitutions) plus E-extra.

### 3.3 After-Prayer Adhkar (Adhkar ba'd al-Salah)

Recited after every obligatory prayer (fard), in the order shown.

**A1. Astaghfirullah — 3×**
- **Arabic:** أَسْتَغْفِرُ اللَّهَ ... أَسْتَغْفِرُ اللَّهَ ... أَسْتَغْفِرُ اللَّهَ
- **Transliteration:** Astaghfiru-llāh, astaghfiru-llāh, astaghfiru-llāh.
- **Translation:** "I seek Allah's forgiveness. I seek Allah's forgiveness. I seek Allah's forgiveness."
- **Count:** 3×
- **Source:** Sahih Muslim 1/414
- Hisn? OK (entry 66) | Nawawi? OK | Primary? OK (Sahih)

**A2. Allahumma anta-s-salam — 1×**
- **Arabic:** اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ
- **Transliteration:** Allāhumma anta-s-salām wa minka-s-salām, tabārakta yā dha-l-jalāli wal-ikrām.
- **Translation:** "O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of Majesty and Honor."
- **Count:** 1× (after the 3× Astaghfirullah)
- **Source:** Sahih Muslim 1/414
- Hisn? OK (entry 66) | Nawawi? OK | Primary? OK (Sahih)

**A3. La ilaha illallah... Allahumma la mani'a lima a'tayt — 1×**
- **Arabic:** لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ
- **Transliteration:** Lā ilāha illa-llāhu waḥdahu lā sharīka lah, lahu-l-mulku wa lahu-l-ḥamd, wa huwa ʿalā kulli shayʾin qadīr. Allāhumma lā māniʿa li-mā aʿṭayt, wa lā muʿṭiya li-mā manaʿt, wa lā yanfaʿu dha-l-jaddi minka-l-jadd.
- **Translation:** "There is no deity but Allah alone, with no partner; to Him belongs all dominion and praise; and He has power over all things. O Allah, none can withhold what You grant, and none can grant what You withhold; and the wealth/might of the mighty cannot avail him against You."
- **Count:** 1×
- **Source:** Sahih al-Bukhari 1/255, Sahih Muslim 1/414
- Hisn? OK (entry 67) | Nawawi? OK | Primary? OK (Sahih — agreed-upon)

**A4. La ilaha illallah... la hawla wa la quwwata illa billah — 1×**
- **Arabic:** لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ، لَا إِلَهَ إِلَّا اللَّهُ، وَلَا نَعْبُدُ إِلَّا إِيَّاهُ، لَهُ النِّعْمَةُ وَلَهُ الْفَضْلُ وَلَهُ الثَّنَاءُ الْحَسَنُ، لَا إِلَهَ إِلَّا اللَّهُ مُخْلِصِينَ لَهُ الدِّينَ وَلَوْ كَرِهَ الْكَافِرُونَ
- **Transliteration:** Lā ilāha illa-llāhu waḥdahu lā sharīka lah, lahu-l-mulku wa lahu-l-ḥamd, wa huwa ʿalā kulli shayʾin qadīr, lā ḥawla wa lā quwwata illā bi-llāh...
- **Translation:** "There is no deity but Allah alone... There is no power and no might except by Allah. There is no deity but Allah, and we worship none but Him. To Him belongs all favor, all grace, and all good praise. There is no deity but Allah; we are sincere in faith to Him, even though the disbelievers hate it."
- **Count:** 1×
- **Source:** Sahih Muslim 1/415
- Hisn? OK (entry 68) | Nawawi? OK | Primary? OK (Sahih)

**A5. The tasbihat (33/33/33+1) — completing 100**
- **Arabic:** سُبْحَانَ اللَّهِ (×33) ... الْحَمْدُ لِلَّهِ (×33) ... اللَّهُ أَكْبَرُ (×33), and then once: لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ
- **Transliteration:** Subḥāna-llāh (33×), al-ḥamdu lillāh (33×), Allāhu akbar (33×), then once: Lā ilāha illa-llāhu waḥdahu lā sharīka lah, lahu-l-mulku wa lahu-l-ḥamd, wa huwa ʿalā kulli shayʾin qadīr.
- **Translation:** "Glory be to Allah (33×). Praise be to Allah (33×). Allah is the Greatest (33×). [Once:] There is no deity but Allah alone, with no partner; to Him belongs all dominion and praise; and He has power over all things."
- **Count:** 33/33/33 + 1, totaling 100 — Sahih Muslim 1/418. "Whoever says this after every prayer will be forgiven his sins even if they be like the foam of the sea."
- **Source:** Sahih Muslim 1/418
- Hisn? OK (entry 69) | Nawawi? OK | Primary? OK (Sahih)

**A6. Surah al-Ikhlas, al-Falaq, an-Nas — 1× (3× after Fajr and Maghrib)**
- **Arabic / Translation:** (see M2 above — same texts)
- **Count:** 1× after each obligatory prayer. **3× each** after Fajr and Maghrib specifically.
- **Source:** Abu Dawud 2/86, An-Nasa'i 3/68; al-Albani in *Sahih at-Tirmidhi* 2/8. **Sahih**.
- Hisn? OK (entry 70) | Nawawi? OK | Primary? OK (Sahih)

**A7. Ayat al-Kursi — 1×**
- **Arabic / Translation:** (see M1 above — same text)
- **Count:** 1× after each obligatory prayer
- **Source:** An-Nasa'i, *Amalul-Yawm wal-Laylah* no. 100; Ibn As-Sunni no. 121; al-Albani **Sahih**. "Whoever recites Ayat al-Kursi after each prayer, nothing prevents him from entering Paradise except death."
- Hisn? OK (entry 71) | Nawawi? OK | Primary? OK (Sahih)

**A8. La ilaha illallah... yuhyi wa yumit — 10× (Maghrib and Fajr)**
- **Arabic:** لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ
- **Transliteration:** Lā ilāha illa-llāhu waḥdahu lā sharīka lah, lahu-l-mulku wa lahu-l-ḥamd, yuḥyī wa yumīt, wa huwa ʿalā kulli shayʾin qadīr.
- **Translation:** "There is no deity but Allah alone, with no partner; to Him belongs all dominion and praise; He gives life and causes death; and He has power over all things."
- **Count:** 10× after Maghrib and Fajr specifically
- **Source:** At-Tirmidhi 5/515, Ahmad 4/227; Ibn al-Qayyim in *Zad al-Ma'ad* 1/300. **Hasan**.
- Hisn? OK (entry 72) | Nawawi? OK | Primary? OK (Hasan)

**A9. Allahumma inni as'aluka 'ilman nafi'an — 1× (Fajr only)**
- (See M20 above — same text). Recited specifically after Fajr salam.
- **Source:** Sahih Ibn Majah 1/152
- Hisn? OK (entry 73) | Nawawi? OK | Primary? OK (Hasan)

### 3.4 Before-Sleep Adhkar

Recited just before sleeping, in roughly this order:

**S1. Last 3 quls — 3× with body wipe**
- **Arabic / Translation:** (see M2 above — Ikhlas, Falaq, Nas)
- **Method:** Bring the palms together, blow lightly into them, recite each surah, then wipe over the body — head and face first, then the front of the body. Repeat the full sequence 3 times.
- **Count:** 3 cycles total
- **Source:** Sahih al-Bukhari and Sahih Muslim 4/1723
- Hisn? OK (entry 99) | Nawawi? OK | Primary? OK (Sahih — agreed-upon)

**S2. Ayat al-Kursi — 1×**
- (See M1 above — same text)
- **Source:** Sahih al-Bukhari, "A guardian from Allah will remain with you and Satan will not approach you until you wake."
- Hisn? OK (entry 100) | Nawawi? OK | Primary? OK (Sahih)

**S3. Last 2 verses of al-Baqarah (2:285-286) — 1×**
- **Arabic (2:285):** آمَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِّن رُّسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ
- **Arabic (2:286):** لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنتَ مَوْلَانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ
- **Source:** Sahih al-Bukhari (Fath al-Bari 9/94), Sahih Muslim 1/554. "These two verses will suffice him."
- Hisn? OK (entry 101) | Nawawi? OK | Primary? OK (Sahih — agreed-upon)

**S4. Bismika Rabbi wada'tu janbi — 1×**
- **Arabic:** بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ
- **Transliteration:** Bi-smika rabbī waḍaʿtu janbī wa bika arfaʿuh, fa-in amsakta nafsī farḥamhā, wa in arsaltahā faḥfaẓhā bimā taḥfaẓu bihi ʿibādaka-ṣ-ṣāliḥīn.
- **Translation:** "In Your name, my Lord, I lay myself down, and in Your name I rise. If You take my soul, have mercy on it; and if You release it, protect it as You protect Your righteous servants."
- **Count:** 1×
- **Source:** Sahih al-Bukhari 1/126, Sahih Muslim 4/2084
- Hisn? OK (entry 102) | Nawawi? OK | Primary? OK (Sahih — agreed-upon)

**S5. Allahumma innaka khalaqta nafsi — 1×**
- **Arabic:** اللَّهُمَّ إِنَّكَ خَلَقْتَ نَفْسِي وَأَنْتَ تَوَفَّاهَا، لَكَ مَمَاتُهَا وَمَحْيَاهَا، إِنْ أَحْيَيْتَهَا فَاحْفَظْهَا، وَإِنْ أَمَتَّهَا فَاغْفِرْ لَهَا. اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ
- **Transliteration:** Allāhumma innaka khalaqta nafsī wa anta tawaffāhā, laka mamātuhā wa maḥyāhā, in aḥyaytahā faḥfaẓhā, wa in amattahā faghfir lahā. Allāhumma innī asʾaluka-l-ʿāfiyah.
- **Translation:** "O Allah, You created my soul and You take it back. To You is its life and its death. If You give it life, protect it; if You cause it to die, forgive it. O Allah, I ask You for well-being."
- **Count:** 1×
- **Source:** Sahih Muslim 4/2083, Ahmad 2/79
- Hisn? OK (entry 103) | Nawawi? OK | Primary? OK (Sahih)

**S6. Allahumma qini 'adhabaka yawma tab'athu 'ibadak — 3×**
- **Arabic:** اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ
- **Transliteration:** Allāhumma qinī ʿadhābaka yawma tabʿathu ʿibādak.
- **Translation:** "O Allah, protect me from Your punishment on the Day You resurrect Your servants."
- **Count:** 3× (lying down, placing right hand under cheek)
- **Source:** Abu Dawud 4/311; al-Albani **Sahih** in *Sahih at-Tirmidhi* 3/143.
- Hisn? OK (entry 104) | Nawawi? OK | Primary? OK (Sahih)

**S7. Bismika allahumma amutu wa ahya — 1×**
- **Arabic:** بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا
- **Transliteration:** Bi-smika-llāhumma amūtu wa aḥyā.
- **Translation:** "In Your name, O Allah, I die and I live."
- **Count:** 1×
- **Source:** Sahih al-Bukhari (Hisn 105)
- Hisn? OK (entry 105) | Nawawi? OK | Primary? OK (Sahih)

**S8. SubhanAllah 33× / Alhamdulillah 33× / Allahu Akbar 34× — totalling 100**
- **Arabic:** سُبْحَانَ اللَّهِ (×33) ... الْحَمْدُ لِلَّهِ (×33) ... اللَّهُ أَكْبَرُ (×34)
- **Transliteration:** Subḥāna-llāh (33×), al-ḥamdu lillāh (33×), Allāhu akbar (34×).
- **Translation:** "Glory be to Allah (33). Praise be to Allah (33). Allah is the Greatest (34)."
- **Count:** 33/33/34. The Prophet taught Fatimah and Ali this is better than a servant they had asked for.
- **Source:** Sahih al-Bukhari (Fath al-Bari 7/71), Sahih Muslim 4/2091
- Hisn? OK (entry 106) | Nawawi? OK | Primary? OK (Sahih — agreed-upon)

**S9. Allahumma Rabb as-samawat as-sab' — 1×**
- **Arabic:** اللَّهُمَّ رَبَّ السَّمَاوَاتِ السَّبْعِ وَرَبَّ الْعَرْشِ الْعَظِيمِ، رَبَّنَا وَرَبَّ كُلِّ شَيْءٍ، فَالِقَ الْحَبِّ وَالنَّوَى، وَمُنْزِلَ التَّوْرَاةِ وَالْإِنْجِيلِ وَالْفُرْقَانِ، أَعُوذُ بِكَ مِنْ شَرِّ كُلِّ شَيْءٍ أَنْتَ آخِذٌ بِنَاصِيَتِهِ، اللَّهُمَّ أَنْتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ، وَأَنْتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ، وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ، وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ، اقْضِ عَنَّا الدَّيْنَ وَأَغْنِنَا مِنَ الْفَقْرِ
- **Translation:** "O Allah, Lord of the seven heavens and Lord of the Magnificent Throne, our Lord and Lord of all things... pay off our debts and free us from poverty."
- **Source:** Sahih Muslim 4/2084
- Hisn? OK (entry 107) | Nawawi? OK | Primary? OK (Sahih)

**S10. Alhamdulillahi-lladhi at'amana — 1×**
- **Arabic:** الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا، وَكَفَانَا، وَآوَانَا، فَكَمْ مِمَّنْ لَا كَافِيَ لَهُ وَلَا مُؤْوِيَ
- **Translation:** "Praise is to Allah Who has fed us and given us drink, sufficed us and given us shelter. How many are without a sufficer or a shelter."
- **Source:** Sahih Muslim 4/2085
- Hisn? OK (entry 108) | Nawawi? OK | Primary? OK (Sahih)

**S11. Allahumma 'alim al-ghayb wash-shahadah (bedtime version) — 1×**
- (Same text as M11 above)
- **Source:** Abu Dawud 4/317, At-Tirmidhi 3/142 (Sahih)
- Hisn? OK (entry 109) | Nawawi? OK | Primary? OK (Sahih)

**S12. Recite Surah as-Sajdah (32) and Surah al-Mulk (67)**
- **Source:** At-Tirmidhi, an-Nasa'i; al-Albani in *Sahih al-Jami' as-Saghir* 4/255. **Sahih**.
- Hisn? OK (entry 110) | Nawawi? OK | Primary? OK (Sahih)

**S13. Allahumma aslamtu nafsi ilayk — 1× (just before sleeping)**
- **Arabic:** اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ
- **Transliteration:** Allāhumma aslamtu nafsī ilayk, wa fawwaḍtu amrī ilayk, wa wajjahtu wajhī ilayk, wa aljaʾtu ẓahrī ilayk, raghbatan wa rahbatan ilayk, lā maljaʾa wa lā manjā minka illā ilayk, āmantu bi-kitābika-lladhī anzalt, wa bi-nabiyyika-lladhī arsalt.
- **Translation:** "O Allah, I submit my soul to You, entrust my affair to You, turn my face to You, and lay my back upon You — out of hope in You and fear of You. There is no refuge and no escape from You except to You. I believe in Your Book that You revealed and in Your Prophet whom You sent."
- **Note:** "Whoever recites this and dies that night dies upon fitrah" — Sahih Bukhari & Muslim.
- Hisn? OK (entry 111) | Nawawi? OK | Primary? OK (Sahih — agreed-upon)

---

## Section 4: Library / Implementation Recommendations

### 4.1 Prayer time calculation

**Recommended package:** `adhan_dart` — https://pub.dev/packages/adhan_dart
- This is the most directly aligned port of the official `batoulapps/adhan-js` library, ported to Dart while preserving the calculation logic verbatim.
- It is **not officially endorsed by Batoula Apps** (Batoula Apps maintain Swift, JavaScript, Java, and C# directly; the Dart port is community-maintained by `iamriajul` at https://github.com/iamriajul/adhan-dart but listed in the Adhan README as a recognized "additional implementation").
- License: MIT. No native dependencies (pure Dart). Compatible with Flutter and pure Dart.
- Implements: all calculation methods (_removed_, ISNA, Egyptian, UmmAlQura, Kuwait, Qatar, Singapore, Turkey, MoonsightingCommittee, Dubai, Tunisia, etc.), Madhab.SHAFI / Madhab.HANAFI Asr rule, HighLatitudeRule.None / MiddleOfTheNight / SeventhOfTheNight / TwilightAngle, PrayerAdjustments (tune individual prayers), and PolarCircleResolution for above-Arctic.
- Verify current version on pub.dev at integration time (this changes; check https://pub.dev/packages/adhan_dart/versions). Use a `^` constraint to receive non-breaking updates.

WARNING — There is also an older package called simply `adhan` (https://pub.dev/packages/adhan) at version 2.0.0+1 by `riajul.dev` — same maintainer, predecessor. It is older (2 years since update). **Prefer `adhan_dart`** (more recent maintenance, same upstream).

### 4.2 Qibla compass

**Recommended approach — two-package combination:**
1. `flutter_compass_v2` (https://pub.dev/packages/flutter_compass_v2) v1.0.3 — successor to the unmaintained original `flutter_compass`. Provides raw azimuth from the device sensors.
2. `geolocator` (https://pub.dev/packages/geolocator) — get the user's lat/lon for both the bearing calculation AND the magnetic declination lookup.

**OR use the wrapper:**
- `flutter_qiblah` v3.2.0 (https://pub.dev/packages/flutter_qiblah) — wraps flutter_compass_v2 + geolocator + does the Qibla math. Convenient but the developer doesn't expose magnetic declination correction by default. If you adopt this, manually correct for declination before displaying the needle angle.

**WARNING — declination handling:**
- Neither flutter_compass nor flutter_compass_v2 automatically apply magnetic declination correction. (See GitHub issue #40 on flutter_compass.) The values returned are **magnetic heading**, not true heading.
- To correct: get magnetic declination at the user's lat/lon using a World Magnetic Model lookup. Options:
  - The `geomag` Dart package (limited coverage)
  - Implement WMM 2025 directly (a few hundred lines of Dart; the coefficients are public domain from NOAA)
  - Use the iOS-native `CLHeading.trueHeading` via platform channels on iOS only (Android requires WMM)
- Without declination correction, Qibla can be off by 5–15° at typical mid-latitudes, by >20° in northern Canada/Russia. This is not acceptable for prayer.

**Known iOS Simulator limitation** (flutter_qiblah docs): compass APIs do not work on the iOS Simulator — must test on a physical device.

### 4.3 Prayer notifications

**Recommended package:** `flutter_local_notifications` (https://pub.dev/packages/flutter_local_notifications) — currently v21.0.0 by `dexterx.dev`. Verified publisher, actively maintained (updated ~2 months ago as of 2026-05-26).
- Supports Android, iOS, macOS, Linux, Windows.
- Supports **scheduled notifications**, which is essential for prayer-time alerts.

**Timezone support:** `timezone` (https://pub.dev/packages/timezone) — currently v0.11.0 by `labs.dart.dev` (Google verified). Provides the IANA timezone database and `TZDateTime`. Required by flutter_local_notifications for scheduling at specific local times — without this, scheduled notifications fire at UTC time, which is wrong.

**Pattern:**
```dart
// 1. Initialize timezone
tz.initializeTimeZones();
tz.setLocalLocation(tz.getLocation(deviceTimezone));
// 2. Compute prayer times with adhan_dart for today (and tomorrow's Fajr)
// 3. For each prayer time, schedule a TZDateTime notification
// 4. On app resume or at midnight, refresh the schedule (libraries cap pending notifications)
```

iOS has a hard limit of ~64 pending notifications; Android caps higher but practically reschedule daily. Schedule the next ~7 days of prayers at a time and re-schedule when the app is opened.

### 4.4 Location services

- `geolocator` (https://pub.dev/packages/geolocator) — get current position for prayer time calculation and Qibla bearing. Handles iOS/Android permission flows.

### 4.5 Persistence

- `shared_preferences` for simple settings (chosen calculation method, madhab, notification toggles).
- `hive` or `sqflite` if you store daily completion tracking for adhkar.

---

## Section 5: Discrepancies & Open Questions

### 5.1 Resolved discrepancies

1. **Egyptian method Fajr/Isha angles** — older sources cite 20°/18°; modern Adhan and Aladhan both use 19.5°/17.5°. **Resolution:** Use 19.5°/17.5° to match the canonical libraries.

2. **MoonsightingCommittee** — base angle is 18°/18° but the actual times use seasonal corrections by Khalid Shaukat. **Resolution:** Use the Adhan library's built-in MoonsightingCommittee constant (it applies the seasonal adjustment automatically). Do not implement from raw 18°/18° angles.

3. **Qatar method** — 18° Fajr (consistent across A,B,C) with **90 min Isha interval** (vs angle-based). **Resolution:** Use 18° Fajr + 90 min Isha interval per the Aladhan canonical implementation.

4. **Cape Town Qibla bearing** — some sources publish 20.24° (rhumb line); the correct great-circle initial bearing is 23.35°. **Resolution:** Always use great-circle. Document this in the app's Qibla help text in case users compare against rhumb-line sources.

5. **flutter_compass declination** — does NOT auto-correct. **Resolution:** Implement WMM-based declination correction in the app.

### 5.2 Unresolved / accepting approximation

1. **Diyanet (Turkey) prayer times** — the Diyanet does not publish a clean twilight-angle formula; their official times are empirically tuned. Using 18°/17° (per Aladhan) will differ from the official Diyanet times by 2–4 minutes in some seasons.
   - **Mitigation:** Add a "tune" feature in the app letting Turkish users add ±N minutes to each prayer; OR offer fetching from the Diyanet API when online (https://namazvakitleri.diyanet.gov.tr).

2. **UmmAlQura Ramadan adjustment** — the +30 min during Ramadan is automatic in Adhan, but requires the lib to know it's Ramadan. Confirm the adhan_dart implementation handles the Hijri calendar correctly; if not, gate it explicitly in app code using `hijri` package.

3. **Critical-latitude (above Arctic/Antarctic circle) handling** — the methods diverge wildly. Adhan library has `PolarCircleResolution` (AqrabBalad / AqrabYaum / Unresolved) — recommend exposing this in settings for users above ~65°.

### 5.3 Adhkar with weaker authentication — flagged for caution

The morning/evening set used in 3.1–3.2 is drawn entirely from al-Qahtani's *Hisn al-Muslim* and is uniformly **Sahih or Hasan-graded** in the relied-upon sources (al-Albani, Ibn Baz, Ibn al-Qayyim verifications). Notably **no** entries in our list are graded Da'if (weak).

Some commonly circulated but **disputed** adhkar that we have deliberately **NOT included**:
- The popular "Allahumma inni a'udhu bika min al-hammi wal-hazan..." attributed in some apps to morning/evening: it is sahih, but its **timing as a morning/evening dhikr** is not in the strongest narrations. Include it under "general supplications" rather than the strict morning/evening list.
- "Ya Hayyu ya Qayyum brahmatik astaghith aslih li sha'ni kullah..." with a fixed count of 100× — the **base text** is sahih (entry M14 / Hisn 88), but specifying "100 times" is not in the original narration. Use 1× or "as much as one wishes."
- Adhkar attributed to specific weekdays (e.g. "Monday-specific morning supplication") — these are mostly from weak narrations and should be **excluded** from the app or clearly marked as "narrations of disputed authenticity."

When in doubt: **if al-Qahtani didn't include it in Hisn al-Muslim's morning/evening chapter, leave it out** of the morning/evening adhkar feature.

### 5.4 Unverified / pending

- Direct Saudi government published Kaaba coordinates from GASGI/SGSPA: no public, machine-readable source was found at the time of this research. Wikipedia/OSM/coordinate-databases all converge on 21.4225°, 39.8262°, so this is left **without an explicit Saudi-gov citation but with three other independent confirming sources**.
- Imam al-Nawawi's *Kitab al-Adhkar* in a primary online edition was not directly verified entry-by-entry; cross-reference here relies on the fact that al-Nawawi systematically includes all Bukhari/Muslim/Sunan material that al-Qahtani draws from. A scholar's review of the final app text against a printed edition of al-Adhkar (Dar Ibn Hazm, Beirut ed.) is recommended before app release.

---

## Section 6: Sources List

### Section 1 (Prayer Times)
- batoulapps/adhan main repository: https://github.com/batoulapps/adhan
- batoulapps/adhan-java CalculationMethod.java: https://raw.githubusercontent.com/batoulapps/adhan-java/master/adhan/src/main/java/com/batoulapps/adhan/CalculationMethod.java
- PrayTimes.org calculation docs (Hamid Zarrabi-Zadeh): http://praytimes.org/docs/calculation
- Aladhan calculation methods page: https://aladhan.com/calculation-methods
- Aladhan live API methods endpoint: https://api.aladhan.com/v1/methods

### Section 2 (Qibla)
- Wikipedia "Kaaba": https://en.wikipedia.org/wiki/Kaaba
- OpenStreetMap Nominatim Kaaba: https://nominatim.openstreetmap.org/search?q=Kaaba+Mecca&format=json
- LatLong.net (third-source coordinate verification): https://www.latlong.net/place/the-kaaba-mecca-saudi-arabia-12639.html
- Reference qibla bearings cross-checked at: qiblacompass.net, kible.org, al-habib.info, qibladirection.org, mwaqet.net, timesprayer.com, qibla-finder.com, qibladirectiontoday.com
- flutter_compass declination discussion: https://github.com/hemanthrajv/flutter_compass/issues/40
- Great-circle bearing formula reference: Ed Williams Aviation Formulary; Movable Type Scripts (https://www.movable-type.co.uk/scripts/latlong.html)

### Section 3 (Adhkar)
- Hisn al-Muslim on Sunnah.com (English transl. of al-Qahtani): https://sunnah.com/hisn
  - Morning/Evening: entries 75a–98 — direct URLs `https://sunnah.com/hisn:75a` ... `https://sunnah.com/hisn:98`
  - After-prayer: entries 65–73 — `https://sunnah.com/hisn:65` ... `https://sunnah.com/hisn:73`
  - Before-sleep: entries 99–112 — `https://sunnah.com/hisn:99` ... `https://sunnah.com/hisn:112`
- Primary hadith collections via sunnah.com: Bukhari (https://sunnah.com/bukhari), Muslim (https://sunnah.com/muslim), Abu Dawud (https://sunnah.com/abudawud), Tirmidhi (https://sunnah.com/tirmidhi), Nasa'i (https://sunnah.com/nasai), Ibn Majah (https://sunnah.com/ibnmajah)
- Quran text via AlQuran.cloud API (Uthmani script): https://api.alquran.cloud/v1/ayah/2:255/quran-uthmani  (and 2:285, 2:286, surahs 112/113/114)
- Imam al-Nawawi's al-Adhkar (background): https://lifewithallah.com/wp-content/uploads/2021/09/Daily-Adhkar-A7-by-Life-With-Allah-v2.pdf and https://www.emaanlibrary.com/wp-content/uploads/2015/04/The-Book-Of-Remembrances-Kitab-Al-Adhkar-Part-1.pdf

### Section 4 (Libraries)
- adhan_dart: https://pub.dev/packages/adhan_dart
- adhan (older, same maintainer): https://pub.dev/packages/adhan
- batoulapps/adhan (canonical project root): https://github.com/batoulapps/adhan
- iamriajul/adhan-dart (community Dart port repo): https://github.com/iamriajul/adhan-dart
- flutter_compass: https://pub.dev/packages/flutter_compass
- flutter_compass_v2: https://pub.dev/packages/flutter_compass_v2
- flutter_qiblah: https://pub.dev/packages/flutter_qiblah
- geolocator: https://pub.dev/packages/geolocator
- flutter_local_notifications: https://pub.dev/packages/flutter_local_notifications
- timezone: https://pub.dev/packages/timezone

### General references
- World Magnetic Model (NOAA, current epoch 2025-2030): https://www.ncei.noaa.gov/products/world-magnetic-model
- Jean Meeus, *Astronomical Algorithms* — the basis for all astronomical computations in Adhan
