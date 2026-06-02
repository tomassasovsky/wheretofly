# Code Simplicity Review — where_to_fly

**Scope:** `lib/`, `packages/*/lib/`, `packages/*/test/`, `test/`  
**Date:** 2026-06-02  
**Focus:** Bugs, behavioral regressions, security, missing tests, YAGNI / unnecessary complexity

---

## Simplification Analysis

### Core Purpose

A Flutter app that lets drone pilots in Argentina:

1. View geofenced restriction zones on a map
2. Configure their ANAC permission level, flight modality, and planned altitude band
3. Tap a location (or search) to get a flight verdict (allowed / allowed with permission / not allowed)
4. Persist preferences and work offline with bundled zone data

The layered architecture (data clients → repositories → cubits → widgets) is appropriate and mostly lean. Complexity concentrates in `map_page.dart` (search + map + location orchestration) and in altitude/MSL overlap logic spread across two models.

---

### Unnecessary Complexity Found

| Issue | Location | Why unnecessary | Suggested simplification |
|-------|----------|-----------------|--------------------------|
| Duplicate altitude-filter logic | `flight_rules_repository.dart:96–114` vs `zonesAtAltitude()` at lines 72–85 | Same horizontal + vertical filter written twice inside `assess()` | Call `zonesAtAltitude()` from `assess()`; derive `skippedByAltitude` as `zonesAt(point).where((z) => !hits.contains(z))` |
| Dead public API | `FlyZone.containsAt()` (fly_zone.dart:92–97), `FlightRulesRepository.zonesAtAltitude()` (only used internally if at all) | Never called from app or other packages | Remove or make private; keep one code path |
| Dead test-only method | `OpenAipAltitudeLimits.appliesAt()` (openaip_altitude_parser.dart:43–58) | Production uses `FlyZone.overlapsAltitudeRange()` instead | Remove `appliesAt()` and test interval overlap via `FlyZone` / repository tests |
| Duplicate haversine | `FlyZone._distanceMeters()` and `OpenAipZonesApiClient._haversine()` | Same formula in two packages | Extract once in `zones_api_client` or use `latlong2` `Distance` |
| Duplicate repository tests | `test/map_cubit_test.dart:8–66` | Mirrors `packages/flight_rules_repository/test/flight_rules_repository_test.dart` almost verbatim | Delete the `FlightRulesRepository` group from app-level test; keep package tests |
| Production debug observer | `bootstrap.dart:16–40` | `AppBlocObserver` logs every cubit change in all builds | Gate behind `kDebugMode` or remove |
| Commented-out UI | `config_sheet.dart:192` | Dead trailing icon code | Delete the comment line |
| Redundant imports | `remote_zones_api_client.dart:4–8`, `bundled_zones_api_client.dart:2–5` | Same symbol imported twice via `src/` and barrel | Single import per file |
| Monolithic map screen | `map_page.dart` (~546 lines) | Search debounce, geocoding, camera, overlays, and map config in one `State` class | Extract a `MapSearchController` or small widget for search state (optional; readability not LOC) |

---

### Code to Remove

| Location | Reason | Est. LOC reduction |
|----------|--------|-------------------|
| `test/map_cubit_test.dart:8–66` | Duplicate of package tests | ~58 |
| `fly_zone.dart:92–97` (`containsAt`) | Unused | ~6 |
| `openaip_altitude_parser.dart:40–58` (`appliesAt`) + related tests | Unused in production; overlap tested elsewhere | ~25 |
| `config_sheet.dart:192` | Commented code | ~1 |
| `bootstrap.dart:16–29` (or gate) | Debug-only observer | ~14 |
| Duplicate import lines in zones clients | Noise | ~4 |
| **Total** | | **~108 (~5% of scoped source)** |

---

### Simplification Recommendations

1. **Consolidate altitude overlap in `assess()`** (most impactful)
   - **Current:** Inline `where(overlapsAltitudeRange)` twice in `assess()`.
   - **Proposed:** `final hits = zonesAtAltitude(point, altitudeRange, groundElevationMslMeters: …);`
   - **Impact:** ~15 LOC saved, single place to fix MSL/AGL bugs.

2. **Align default altitude to 122 m**
   - **Current:** `AltitudeRange.openCategoryDefault` and `SettingsRepository.defaultFlightAltitudeMaxMetersAgl` use **120 m**; `FlightAssessment.maxOpenCategoryAltitudeMetersAgl` and permission slider cap use **122 m** (ANAC open category).
   - **Proposed:** Single constant (122.0) referenced everywhere.
   - **Impact:** Fixes subtle default vs slider/regulatory mismatch; ~0 LOC if constant is shared.

3. **Disable tap on locked modalities**
   - **Current:** `_OptionTile` shows lock icon but `onTap` always fires (`config_sheet.dart:65–67`).
   - **Proposed:** `onTap: locked ? null : () => cubit.selectModality(modality)`.
   - **Impact:** Prevents confusing state where user selects a modality they cannot hold.

4. **Remove duplicate test group from app `test/`**
   - **Current:** Two copies of the same repository scenarios.
   - **Proposed:** App test file tests only `MapCubit`; repository tests stay in package.
   - **Impact:** ~58 LOC, faster CI, one place to update assertions.

5. **Gate or remove `AppBlocObserver`**
   - **Current:** Always registered; logs full state on every emit.
   - **Proposed:** `if (kDebugMode) Bloc.observer = const AppBlocObserver();`
   - **Impact:** Less noise and minor perf win in release builds.

---

### YAGNI Violations

| Feature / abstraction | Why it violates YAGNI | What to do instead |
|----------------------|----------------------|-------------------|
| `OpenAipAltitudeLimits.appliesAt()` | Point-check API not used when assessing ranges | Delete; rely on `FlyZone.overlapsAltitudeRange` |
| `FlyZone.containsAt()` | Single-altitude check unused; app uses bands | Delete |
| `FlightRulesRepository.zonesAtAltitude()` as public API | Only needed inside `assess()` today | Make private or inline via shared helper |
| `AppBlocObserver` in release | Debugging aid shipped to users | Debug-only |
| Geocoding offline cache for `search` only | `reverse()` has no cache; asymmetric feature | Either add reverse cache or document search-only (don't half-build) |
| `groundElevationMslMeters` parameter everywhere defaulting to 0 | Implies terrain support that doesn't exist | Pass explicit 0 and document limitation in UI, or integrate elevation before exposing MSL zones |

---

## Bugs, Regressions, and Behavioral Issues

### Critical

#### 1. MSL zone checks assume ground elevation = 0 m

**Files:** `flight_rules_repository.dart:89–95`, `fly_zone.dart:51–80`, all `assess()` call sites

Vertical overlap converts AGL to MSL via `groundElevationMslMeters`, which **defaults to 0** everywhere. In elevated terrain (e.g. Andes foothills), a flight at 122 m AGL can be well above an MSL floor that would block it if ground elevation were known. The app can report **allowed** when a real MSL-controlled zone should apply.

The package test at `flight_rules_repository_test.dart:80–104` validates skip behavior with `groundElevationMslMeters: 0`; it does not cover high-terrain false negatives.

**Recommendation:** Document prominently in the assessment card when MSL-limited zones are skipped, and/or integrate a terrain/elevation source before treating OpenAIP MSL limits as authoritative. At minimum, treat unknown elevation conservatively (flag uncertainty).

---

### Important

#### 2. Locked flight modalities remain selectable

**File:** `config_sheet.dart:61–67`

Modality tiles show a lock when `state.permission.rank < modality.minimumPermission.rank`, but `onTap` still calls `selectModality`. Users can select BVLOS/night/over-people under recreational permission; verdict becomes `notAllowed` globally, which is confusing and looks like a bug.

**Fix:** `onTap: locked ? null : () => cubit.selectModality(modality)`.

#### 3. Default planned altitude 120 m vs regulatory 122 m

**Files:** `altitude_range.dart:15–19`, `settings_repository.dart:23`, vs `flight_assessment.dart:23`, `permission_level.dart:68–69`

Fresh installs default to 0–**120** m while the open-category ceiling and slider max are **122** m. Users may think 121–122 m is in range when defaults never reach it until they move the slider.

**Fix:** Use one shared constant (122.0) for defaults and ceiling.

#### 4. Duplicate repository tests in app test suite

**File:** `test/map_cubit_test.dart:8–66`

Duplicates package tests with slightly different wording (`blockingZones` vs same assertions). Maintenance burden and drift risk.

**Fix:** Remove duplicate group; keep `MapCubit` blocTests only.

#### 5. Missing test coverage for high-risk paths

| Area | Package / file | Gap |
|------|----------------|-----|
| Geocoding | `geocoding_api_client`, `geocoding_repository` | No unit tests for parsing, Argentina bbox filter, cache fallback |
| Settings persistence | `settings_repository`, `MapCubit` + settings | No tests for altitude persistence, legacy key migration, permission restore |
| OpenAIP parsing | `openaip_zones_api_client` | Only altitude parser tested; no polygon→circle, category mapping, or exclusion list tests |
| Settings UI | `settings_cubit` | No tests for locale/theme round-trip |
| Map search race | `map_page.dart` `_runSearch` | Request-id guard is good but untested (widget or extracted class test) |
| `clearSelection` / `selectAltitudeRange` | `map_cubit` | Not covered in blocTests |

#### 6. Settings writes not awaited from cubit

**File:** `map_cubit.dart:42, 54, 87–90`

`_settings?.setPermissionId(...)` and `setModalityId` return `Future` but are fire-and-forget. Rapid toggles or process kill could lose last preference (low probability on mobile).

**Fix:** `unawaited` with documented intent, or await in cubit methods.

---

### Suggestions

#### 7. Geocoding HTTP client has no timeout

**File:** `geocoding_api_client.dart:34–39`

OpenAIP and remote zones use timeouts (8–10 s); Photon geocoding can hang indefinitely on bad networks.

**Fix:** `.timeout(const Duration(seconds: 10))` on GET calls.

#### 8. API keys via `--dart-define`

**File:** `bootstrap.dart:51–52`

`OPENAIP_API_KEY` is compile-time embedded (visible in binary). Acceptable for many apps; document that keys should be restricted/rate-limited server-side if possible. Not a blocker.

#### 9. Third-party geocoding privacy

**File:** `geocoding_api_client.dart`

Reverse geocoding sends precise coordinates to `photon.komoot.io`. Consider privacy disclosure in app copy / resources page.

#### 10. `FlightRulesRepository._safe` swallows all errors

**File:** `flight_rules_repository.dart:54–61`

Silent fallback to bundled data is correct for resilience but hides feed failures. Optional: log in debug or surface a non-blocking banner when live feeds fail.

#### 11. Circular zone approximation

**File:** `openaip_zones_api_client.dart`

Polygon→circle approximation is a domain simplification, not a code simplicity issue. Worth a user-facing caveat (already partially in bundled client docs).

---

## Security Notes

| Topic | Severity | Notes |
|-------|----------|-------|
| API keys in binary | Low | Standard mobile pattern; restrict key in OpenAIP dashboard |
| Remote GeoJSON URL | Low | No TLS pinning; supply trusted URL via dart-define |
| Location / geocoding data | Low | Sent to device GPS and Photon; disclose in privacy text |
| URL launching | Low | `resources_page.dart` uses `launchUrl` with external browser — OK |
| Storage | Low | SharedPreferences for non-sensitive prefs and geocode cache — OK |

No hardcoded secrets found in scoped source.

---

## Architecture Assessment

**Strengths:**

- Clear package boundaries: zones API, flight rules, geocoding, settings, location, storage
- Thin cubits (`MapCubit`, `SettingsCubit`) with most logic in repositories
- Offline-first bundled zones with optional live merge
- Localization separated via `localized_labels.dart` extensions
- Meaningful repository tests for altitude overlap and verdict rules

**Weaknesses:**

- UI orchestration bloated in `_MapViewState`
- Altitude/MSL logic split between parser, `FlyZone`, and repository with unused APIs
- Test duplication and gaps on networking/persistence layers

---

## Missing Tests — Priority List

1. **P0:** MSL overlap with non-zero `groundElevationMslMeters` (repository)
2. **P0:** `MapCubit.selectAltitudeRange` + settings persistence round-trip
3. **P1:** `GeocodingApiClient.search` / `reverse` parsing and bbox filter (mock HTTP)
4. **P1:** `GeocodingRepository` cache hit on network failure
5. **P1:** `OpenAipZonesApiClient._parse` / category mapping (fixture JSON)
6. **P2:** `SettingsCubit` theme/locale emit after repository write
7. **P2:** Remove duplicate tests when consolidating

---

## Final Assessment

| Metric | Value |
|--------|-------|
| **Total potential LOC reduction** | ~5–8% of scoped source (~108 lines definite dead/duplicate) |
| **Complexity score** | **Medium** — architecture is sound; map screen and altitude paths add cognitive load |
| **Recommended action** | **Proceed with simplifications** — fix Critical/Important items before treating MSL/OpenAIP data as safety-critical |

### Verdict: **Needs work**

The codebase is well-structured and mostly minimal, but a flight-safety app must not silently assume sea-level ground for MSL airspace, and several UX/test gaps should be closed before merge.

---

## Findings Summary (for tracking)

| Severity | Count | Items |
|----------|-------|-------|
| **Critical** | 1 | MSL checks with ground elevation always 0 |
| **Important** | 6 | Locked modalities tappable; 120 vs 122 m defaults; duplicate tests; missing tests; unawaited settings writes; assess/zonesAtAltitude duplication |
| **Suggestions** | 8 | Dead APIs; AppBlocObserver; geocoding timeout; map_page split; duplicate haversine; cache asymmetry; error swallowing; privacy note |
