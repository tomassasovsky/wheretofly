# Architecture Review

**Project:** where_to_fly (Dónde Volar)  
**Scope:** `lib/`, `packages/*/lib/`, `packages/*/test/`, `test/`  
**Date:** 2026-06-02  
**Stack:** Flutter, Bloc/Cubit, layered monorepo (data clients → repositories → presentation)

---

## Executive Summary

The project follows VGV's layered monorepo pattern well at a high level: data clients are isolated in `packages/`, repositories compose them, and `bootstrap.dart` wires dependencies before `runApp`. Cubits (`MapCubit`, `SettingsCubit`) hold map and app-settings business logic with immutable Equatable state.

However, there is a **critical safety regression** in zone loading: when any live feed returns data, the bundled offline snapshot is discarded entirely rather than merged. Configuring only OpenAIP (`--dart-define=OPENAIP_API_KEY=…`) silently removes national parks, government prohibited zones, and critical infrastructure from the map. For a drone-restriction app, this is a merge-blocking defect.

Additional important issues include a presentation-layer import of the data client, substantial search/location orchestration living in `MapView` instead of a cubit, weak test coverage outside `flight_rules_repository`, and several behavioral gaps in persistence and UI gating.

**Verdict:** Fix 2 critical issues before merging; address important layer and test gaps in the same PR or immediately after.

---

## Architecture Overview

```
Presentation (lib/)
  ├── app/app.dart          — RepositoryProvider + SettingsCubit
  ├── map/cubit/            — MapCubit (flight assessment)
  ├── map/view/             — MapPage, widgets
  └── settings/             — SettingsCubit

Domain / Repository (packages/*_repository)
  ├── flight_rules_repository  — zone mapping + assess()
  ├── geocoding_repository     — search/reverse + cache
  ├── settings_repository      — persisted prefs
  └── location_repository      — device location

Data (packages/*_client, storage)
  ├── zones_api_client         — bundled, remote GeoJSON, OpenAIP
  ├── geocoding_api_client     — Photon API
  ├── location_client          — geolocator wrapper
  └── storage                  — SharedPreferences
```

Intended dependency direction: **Presentation → Repository → Data**. Composition root (`bootstrap.dart`) may import data clients directly — that is correct.

---

## Layer Separation

**Violations found: 1**

| Location | Violation |
|----------|-----------|
| `lib/map/view/widgets/search_results_overlay.dart:2` | Presentation imports `package:geocoding_api_client/geocoding_api_client.dart` directly instead of `package:geocoding_repository/geocoding_repository.dart`, which already re-exports `GeocodeResult`, `GeocodingFailure`, and `GeocodingException`. |

**Clean files (checked):**

- `lib/app/app.dart` — imports repositories only
- `lib/map/cubit/map_cubit.dart` — imports `flight_rules_repository`, `settings_repository`
- `lib/map/view/map_page.dart` — imports repositories (not api clients), though see State Management for logic placement
- All `packages/*_repository/lib/**` — depend on data layer, not Flutter/presentation
- All `packages/*_client/lib/**` — no Flutter or repository imports

**Composition root (acceptable):**

- `lib/bootstrap.dart:7–13` imports `geocoding_api_client` and `zones_api_client` to construct repositories. This is the correct place for data-layer wiring.

**Internal domain smell (not a cross-layer violation):**

- `packages/flight_rules_repository/lib/src/models/permission_level.dart:1` imports `flight_assessment.dart`, while `flight_assessment.dart:5` imports `permission_level.dart`. Dart resolves this cycle, but `PermissionLevel.maxPlannedAltitudeMetersAgl` depends on constants defined on `FlightAssessment`, coupling two domain models. Move altitude ceiling constants to `altitude_range.dart` or a dedicated constants file.

---

## State Management Assessment

### MapCubit — **Issues found**

| Check | Status | Detail |
|-------|--------|--------|
| Naming | ✅ | Descriptive cubit and state names |
| Immutability | ✅ | `MapState` uses `copyWith`, Equatable |
| Business logic location | ✅ | Permission/modality/altitude selection and `assess()` calls live in cubit |
| Data access | ✅ | Calls `FlightRulesRepository` and `SettingsRepository`, not api clients |
| Provider lifecycle | ✅ | Created in `MapPage` via `BlocProvider` |
| Persistence | ⚠️ | `selectPermission`, `selectModality`, `_persistAltitude` call `_settings?.setPermissionId(...)` / `setModalityId` / `setFlightAltitudeRangeAgl` without `await`. Writes are fire-and-forget; a fast app kill can lose the last selection. |

**Files:** `lib/map/cubit/map_cubit.dart:41–43`, `54–55`, `86–90`

### SettingsCubit — **Correct**

- Maps domain `AppThemeMode` ↔ Flutter `ThemeMode` at the presentation boundary (good separation).
- Persists via `SettingsRepository` with awaited writes.
- Immutable `SettingsState` with Equatable.

**File:** `lib/settings/settings_cubit.dart`

### MapView (_MapViewState) — **Issues found**

A large amount of orchestration lives in the UI layer rather than a cubit:

| Concern | Location | Issue |
|---------|----------|-------|
| Search debounce + query | `map_page.dart:203–235` | 250 ms debounce, min-length guard, stale-request cancellation |
| Geocoding search/reverse | `map_page.dart:136–159`, `237–258` | Direct `GeocodingRepository` reads from widget state |
| Location fetch | `map_page.dart:280–299` | Direct `LocationRepository` read, snackbar error mapping |
| Local UI state | `map_page.dart:74–83` | `_searchResults`, `_searchError`, `_searching`, `_showSearchResults` |

This makes the search/location flows untestable with `blocTest`, duplicates error-mapping logic in the widget, and violates the VGV convention that presentation widgets render state and dispatch events — not call repositories directly.

**Recommendation:** Extract a `MapSearchCubit` (or extend `MapCubit`) for search query, results, loading, and reverse-geocode label resolution. Keep `_MapViewState` limited to `GoogleMapController` and focus/animation concerns.

### Config sheet locked modalities — **Behavioral bug**

`lib/map/view/widgets/config_sheet.dart:65–67` sets `locked: state.permission.rank < modality.minimumPermission.rank` but still passes `onTap: () => cubit.selectModality(modality)`. The lock icon is decorative; users can select modalities their permission does not support. The assessment correctly returns `notAllowed`, but the UI implies the option is blocked.

**Fix:** `onTap: locked ? null : () => cubit.selectModality(modality)` (and optionally mute tile styling).

---

## Dependency Direction

**Direction violations: 0 cross-package cycles affecting build**

| Edge | Status |
|------|--------|
| Presentation → Repository | ✅ Clean (except one data-client import noted above) |
| Repository → Data | ✅ Clean |
| Data → Presentation/Repository | ✅ None found |
| `bootstrap.dart` → Data + App | ✅ Composition root |

**Minor internal coupling in `zones_api_client`:**

- `bundled_zones_api_client.dart:2–5` and `remote_zones_api_client.dart:4–8` cross-import each other (doc references + `show` re-exports). No runtime circular dependency, but the imports exist only for documentation. Prefer referencing types in doc comments without importing.

**SDK constraint mismatch:**

| Package | SDK constraint |
|---------|----------------|
| Root `pubspec.yaml` | `>=3.5.0 <4.0.0` |
| All `packages/*/pubspec.yaml` | `>=3.6.0 <4.0.0` |

The app declares a lower floor than its path packages. Align root to `>=3.6.0 <4.0.0` to avoid resolution surprises.

---

## Critical Bugs & Safety Issues

### 1. Live feeds replace bundled zones instead of merging (CRITICAL)

**File:** `packages/flight_rules_repository/lib/src/flight_rules_repository.dart:39–51`

```dart
final merged = <String, ZoneData>{};
for (final zone in [...fromGeojson, ...fromOpenAip]) {
  merged[zone.id] = zone;
}
final data =
    merged.isNotEmpty ? merged.values.toList() : await bundled.fetchZones();
```

When **any** live source returns at least one zone, the bundled snapshot (~100+ airports, national parks, prohibited government sites, critical infrastructure) is **never included**.

**Reproduction:** Build with `--dart-define=OPENAIP_API_KEY=<key>` and no `ZONES_FEED_URL`. OpenAIP returns airspaces only. All bundled prohibited zones (Plaza de Mayo, Casa Rosada, nuclear plants, 35 national parks) disappear from the map. A pilot tapping those locations sees "allowed" in open airspace.

**Expected behavior:** Bundled zones should always form the baseline; live feeds should overlay/override by id. The bootstrap comment ("merged and become the source of truth") describes de-duplication among live feeds, not replacement of the offline safety net.

**Severity:** Critical — incorrect flight verdicts in a safety-critical domain.

### 2. Remote GeoJSON parser ignores vertical limits (CRITICAL for altitude-aware feeds)

**File:** `packages/zones_api_client/lib/src/remote_zones_api_client.dart:90–99`

`_parseFeature` reads `id`, `name`, `categoryId`, coordinates, `radiusMeters`, `allowedPermissionIds`, and `details` but **does not** map `lowerLimitMetersAgl`, `upperLimitMetersAgl`, `lowerLimitMetersMsl`, or `upperLimitMetersMsl` from properties — even though `ZoneData` supports them and `FlightRulesRepository.assess()` uses vertical overlap.

OpenAIP parsing (`openaip_zones_api_client.dart:133–148`) correctly populates altitude fields. A self-hosted GeoJSON feed with vertical limits would be treated as applying at all altitudes, potentially blocking flights that should be allowed below a TMA floor.

**Severity:** Critical when `ZONES_FEED_URL` is the authoritative source and includes altitude metadata.

### 3. OpenAIP API key via `--dart-define` (IMPORTANT security note)

**File:** `lib/bootstrap.dart:52`, `packages/zones_api_client/lib/src/openaip_zones_api_client.dart:82`

`String.fromEnvironment('OPENAIP_API_KEY')` embeds the key in the compiled binary. Acceptable for development; for production, prefer a backend proxy or runtime secure storage. Document that the key is extractable via reverse engineering.

---

## Behavioral Regressions & Logic Gaps

| Issue | Location | Impact |
|-------|----------|--------|
| Geocoding `reverse()` not cached | `geocoding_repository.dart:38–41` | Search has offline cache fallback; reverse geocode on map tap always hits network. Offline tap shows coordinates only. |
| Empty search maps to `noResults` error | `map_page.dart:248` | Empty API result sets `_searchError = GeocodingFailure.noResults` even when the request succeeded — semantically OK but conflates "no matches" with exception path. |
| Duplicate repository tests | `test/map_cubit_test.dart:8–66` | Same scenarios already covered in `packages/flight_rules_repository/test/`. App-level test file should focus on cubit behavior only. |
| Circular zone approximation | `openaip_zones_api_client.dart:123–127` | Polygon → centroid + max radius can include/exclude points incorrectly near complex airspace boundaries. Documented limitation; not a code bug but affects verdict accuracy. |

---

## Package Structure

| Package | Status | Findings |
|---------|--------|----------|
| `flight_rules_repository` | ✅ Complete | Clear domain models, repository API, tests present. Fix zone merge logic. |
| `zones_api_client` | ⚠️ Partial | Manifest, exports, altitude parser test. Missing tests for `RemoteZonesApiClient`, `OpenAipZonesApiClient`, `BundledZonesApiClient`. No `analysis_options.yaml`. |
| `geocoding_api_client` | ⚠️ Partial | No tests. Description still says "Nominatim" but implementation uses Photon (`geocoding_api_client.dart:7–8`). |
| `geocoding_repository` | ⚠️ Partial | Re-exports api types (good for layer boundary). No tests for cache hit/miss paths. |
| `settings_repository` | ⚠️ Partial | No tests for altitude range migration (`_altitudeLegacyKey`). |
| `location_repository` | ⚠️ Partial | Thin pass-through; no tests. |
| `location_client` | ⚠️ Partial | No tests for permission flow mapping. |
| `storage` | ⚠️ Partial | No tests. Flutter-dependent (acceptable for prefs). |

**Linting:** Only root `analysis_options.yaml` exists. Packages declare `very_good_analysis` in dev_dependencies but do not include their own `analysis_options.yaml` with `include: ../../analysis_options.yaml`. Standalone package analysis may not pick up project rules.

**App `pubspec.yaml`:** Does not depend on `geocoding_api_client` or `zones_api_client` directly (good). Transitive access is via repositories and bootstrap.

---

## Test Coverage Assessment

**Existing tests (5 test files):**

| File | Coverage |
|------|----------|
| `packages/flight_rules_repository/test/flight_rules_repository_test.dart` | Core assess logic, altitude overlap — good |
| `packages/zones_api_client/test/openaip_altitude_parser_test.dart` | Altitude parsing — good |
| `test/map_cubit_test.dart` | MapCubit bloc tests + duplicated repository tests |

**Missing tests (priority order):**

1. **`FlightRulesRepository.load` merge behavior** — bundled baseline preserved when live feeds partial; id de-duplication; fallback on all feeds failing.
2. **`RemoteZonesApiClient`** — GeoJSON parsing including altitude properties once fixed.
3. **`GeocodingRepository`** — cache write on success, cache read on network failure, reverse behavior.
4. **`MapCubit` + `SettingsRepository`** — persistence of permission/modality/altitude on selection (mock storage).
5. **`SettingsCubit`** — locale/theme persistence and `ThemeMode` mapping.
6. **`GeocodingApiClient`** — JSON parsing, Argentina bbox filter, error mapping (mock HTTP).
7. **`LocationClient` / `LocationRepository`** — permission denied paths (mock geolocator).

**Test execution:** `very_good test -r` exited with code 69 in this environment (likely workspace/tooling setup). Tests should be verified locally before merge.

---

## Security Review (Static)

| Area | Finding | Severity |
|------|---------|----------|
| API keys | `OPENAIP_API_KEY` compile-time via `--dart-define` | Important — extractable from binary |
| Remote feeds | `ZONES_FEED_URL` compile-time URI; no TLS pinning | Suggestion — standard HTTP client |
| Geocoding | Public Photon API, no secrets | OK |
| Storage | SharedPreferences, non-sensitive prefs | OK |
| Location | Runtime permission via geolocator | OK |
| Input validation | GeoJSON/OpenAIP JSON parsed with type checks; malformed data skipped or throws | OK |

No hardcoded secrets found in source.

---

## Recommendations (Prioritized)

### Must fix before merge

1. **Merge bundled zones with live feeds** in `FlightRulesRepository.load` — bundled as baseline, live feeds override by id.
2. **Parse vertical limits from remote GeoJSON** properties in `RemoteZonesApiClient._parseFeature`.

### Should fix soon

3. Change `search_results_overlay.dart` import to `geocoding_repository`.
4. Move search/location orchestration from `MapView` to a cubit.
5. Await settings persistence in `MapCubit` (or expose `Future<void>` selectors).
6. Disable `onTap` for locked modalities in `config_sheet.dart`.
7. Break `PermissionLevel` ↔ `FlightAssessment` circular dependency.
8. Add tests for zone merge and geocoding cache.

### Suggestions

9. Align SDK constraints across root and packages.
10. Add `analysis_options.yaml` to each package.
11. Remove duplicated repository tests from `test/map_cubit_test.dart`.
12. Add offline cache for reverse geocoding.
13. Update `geocoding_api_client` package description (Photon, not Nominatim).

---

## Verdict

**Fix 2 critical violations before merging.**

The layered architecture is sound and mostly consistent with VGV conventions. The composition root, repository providers, and cubit patterns are well applied. The zone-loading merge bug and missing GeoJSON altitude parsing are safety-critical for this app's purpose and must be addressed before release. Layer boundary cleanup, cubit extraction for search, and test coverage gaps should follow immediately.

---

## Appendix: Files Reviewed

**Presentation:** `lib/main.dart`, `lib/bootstrap.dart`, `lib/app/app.dart`, `lib/settings/settings_cubit.dart`, `lib/map/cubit/map_cubit.dart`, `lib/map/cubit/map_state.dart`, `lib/map/view/map_page.dart`, `lib/map/view/widgets/*`, `lib/theme/app_theme.dart`, `lib/resources/view/*`, `lib/l10n/localized_labels.dart`

**Repositories:** all files under `packages/flight_rules_repository`, `geocoding_repository`, `settings_repository`, `location_repository`

**Data:** all files under `packages/zones_api_client`, `geocoding_api_client`, `location_client`, `storage`

**Tests:** `test/map_cubit_test.dart`, `packages/flight_rules_repository/test/*`, `packages/zones_api_client/test/*`
