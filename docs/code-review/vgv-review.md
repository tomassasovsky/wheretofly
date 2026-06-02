# VGV Code Review

**Project:** where_to_fly (Flutter / Dart monorepo)  
**Scope:** `lib/`, `packages/*/lib/`, `packages/*/test/`, `test/`  
**Review date:** 2026-06-02  
**Stack:** Flutter, Cubit (`bloc`), layered packages, `very_good_analysis`

---

## Summary

The project follows VGV’s layered monorepo shape well: data clients and repositories live under `packages/`, `MapCubit` owns flight-rule state, and `FlightRulesRepository` centralizes verdict logic with solid unit tests including altitude overlap cases. The main gaps are **presentation-layer bloat** (`MapView` ~450 lines with geocoding/search/location orchestration), **missing tests** for several cubits and repositories (notably altitude persistence and geocoding cache policy), and a few **behavioral/UI bugs** (locked modalities still selectable and persisted). MSL-based zone checks always assume `groundElevationMslMeters = 0`, which can mis-rank vertical overlap near elevated terrain—acceptable as a documented limitation only if the UI says so.

**Verdict:** Needs work before merge—not due to architecture collapse, but due to test gaps on new altitude/settings flows, UI guard bugs, and safety-adjacent altitude modeling assumptions that should be explicit or improved.

**Test run during review:** `very_good test` exited with code 69 (likely unresolved workspace / `pub get`). Static review of existing tests suggests they are well-written where present; re-run after `flutter pub get`.

---

## 🔴 Critical — Must Fix Before Merge

### 1. `lib/map/view/widgets/config_sheet.dart:67` — Locked flight modalities remain tappable and persist

- **Issue:** `_OptionTile` shows a lock icon when `locked` is true but still wires `onTap: () => cubit.selectModality(modality)`. `MapCubit.selectModality` does not validate permission rank against `modality.minimumPermission`.
- **Why:** Users with recreational/registered permission can select BVLOS/night/over-people, which is persisted via `SettingsRepository.setModalityId`. Verdicts become globally `notAllowed` (safe but wrong UX), and stored settings contradict the lock affordance—violates “permission-aware” product promise and will confuse support/debugging.
- **Fix:** Disable tap when locked and guard in the cubit:

```dart
// config_sheet.dart — _OptionTile
onTap: locked ? null : onTap,

// map_cubit.dart
void selectModality(FlightModality modality) {
  if (state.permission.rank < modality.minimumPermission.rank) return;
  _settings?.setModalityId(modality.id);
  emit(_reassessed(state.copyWith(modality: modality)));
}
```

Add a `blocTest` that recreational permission cannot emit BVLOS after a tap/API call.

---

### 2. `packages/flight_rules_repository/lib/src/flight_rules_repository.dart:94` — MSL vertical limits use zero ground elevation

- **Issue:** `assess()` and `FlyZone.overlapsAltitudeRange()` default `groundElevationMslMeters = 0`. OpenAIP and bundled zones often express floors in MSL (e.g. 3000 ft MSL). Without terrain elevation, a 0–122 m AGL flight band is compared against MSL limits as if the ground were at sea level.
- **Why:** Near the Andes or high plateaus, users may see **false negatives** (zone skipped when it should apply) or **false positives** (zone applies when flight is actually below the MSL floor). For a drone zone checker, this is a correctness risk that undermines trust.
- **Fix (minimum):** Surface in UI copy that MSL limits are approximate without terrain data. **Better:** integrate a coarse elevation source (or conservative buffer) and thread `groundElevationMslMeters` from tap location into `MapCubit.checkPoint` / `_reassessed`. Add tests mirroring `high MSL floor excludes zone at 122 m AGL` with non-zero ground elevation.

---

## 🟡 Important — Should Fix

### 3. `test/map_cubit_test.dart` — Missing coverage for altitude range and settings integration

- **Issue:** `MapCubit` gained `altitudeRange`, `selectAltitudeRange`, `_persistAltitude`, and settings hydration, but tests only cover permission/modality/checkPoint. No tests for `clearSelection`, altitude clamping on permission change, or persistence callbacks.
- **Why:** VGV expects every cubit to have meaningful state-transition tests; altitude is core to the new vertical-limit feature.
- **Fix:** Add `blocTest`s with a mock/fake `SettingsRepository` verifying `setFlightAltitudeRangeAgl` on `selectAltitudeRange` and clamping when switching to open-category permission.

---

### 4. `lib/settings/settings_cubit.dart` — No unit tests

- **Issue:** `SettingsCubit` maps `SettingsRepository` ↔ `ThemeMode`/`Locale` with async persistence; zero tests in `test/`.
- **Why:** Regressions in theme/locale wiring break the whole app shell silently.
- **Fix:** `blocTest` with mocked storage-backed repository (or fake repository) for `setLanguage`, `setThemeMode`, and initial state hydration.

---

### 5. `packages/geocoding_repository/lib/src/geocoding_repository.dart` — Cache policy untested; reverse not cached

- **Issue:** Search caches only the **first** result on success; network failure returns a single cached entry. `reverse()` always hits the network with no offline fallback. README claims cached search works offline but does not qualify reverse geocoding.
- **Why:** Offline tap-to-check shows coordinates fallback only (`map_page.dart:155–158`); inconsistent with “works offline” narrative. Cache key uses trimmed lowercase query—edge cases (labels with `|`) are handled but never tested.
- **Fix:** Package-level tests with fake `GeocodingApiClient` + in-memory `Storage` for cache hit on network error. Document reverse behavior or add reverse cache keyed by lat/lon.

---

### 6. `lib/map/view/map_page.dart` — Business logic and data orchestration in the UI layer

- **Issue:** `_MapViewState` owns debounced search, request de-duplication (`_latestSearchRequest`), geocoding/location repository calls, Argentina bounds checks, and camera moves (~200 lines of non-rendering logic).
- **Why:** Violates VGV layer separation (“UI dispatches, cubit/repository decides”). Hard to unit test race conditions (stale search responses) without widget tests.
- **Fix:** Extract a `MapSearchCubit` or `GeocodingSearchCubit` (or methods on `MapCubit`) for search state; keep `MapView` as layout + `BlocListener`. Prioritize at least extracting `_runSearch` / `_resolveAddressForPoint` with tests for cancellation semantics.

---

### 7. `lib/bootstrap.dart:15–28` — `AppBlocObserver` logs every cubit change in all builds

- **Issue:** `Bloc.observer` logs full `Change` objects via `dart:developer` `log` with no `kDebugMode` guard.
- **Why:** Noisy in profile/release, minor perf/privacy concern (state may include coordinates).
- **Fix:** Register observer only in debug/profile:

```dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  Bloc.observer = const AppBlocObserver();
}
```

---

### 8. `lib/bootstrap.dart:51–62` — API keys and feed URLs via `--dart-define`

- **Issue:** `OPENAIP_API_KEY` is compiled into the app binary; `ZONES_FEED_URL` is not validated before `Uri.parse`.
- **Why:** Keys in client binaries are extractable; a malformed define causes startup failure or unexpected URI behavior.
- **Fix:** Document that OpenAIP keys are not secrets (rate-limited public tier). Prefer CI secrets + build flavors for production. Validate `Uri.tryParse` and non-empty host before constructing clients.

---

### 9. `packages/zones_api_client/lib/src/openaip_zones_api_client.dart` — Polygon → circle approximation

- **Issue:** Airspace polygons become centroid + max vertex distance (min 500 m). Narrow corridors and irregular shapes are poorly approximated.
- **Why:** Users may think they are clear inside a polygon edge or falsely inside a restriction. README mentions this; the app UI does not repeat the caveat near verdicts.
- **Fix:** Add brief disclaimer in `ZoneDetailCard` or resources when any hit zone id starts with `openaip_`. Long-term: render polygons on the map.

---

### 10. `packages/flight_rules_repository/lib/src/flight_rules_repository.dart:54–61` — Silent feed failures

- **Issue:** `_safe` swallows all errors and returns `[]`, so failed remote/OpenAIP feeds merge away without user-visible degradation beyond falling back to bundle when **all** feeds empty.
- **Why:** If GeoJSON succeeds with stale/partial data while OpenAIP fails, user gets incomplete airspace with no warning.
- **Fix:** Return metadata (`loadWarnings`) or log/report count of zones per source in debug; optional in-app “data updated / offline snapshot” banner.

---

### 11. `test/map_cubit_test.dart:8–66` — Duplicated `FlightRulesRepository` tests

- **Issue:** Same repository scenarios exist in `packages/flight_rules_repository/test/flight_rules_repository_test.dart` (with richer altitude cases in the package test).
- **Why:** Duplicate maintenance; package tests are the canonical home per monorepo conventions.
- **Fix:** Remove the `group('FlightRulesRepository')` from `test/map_cubit_test.dart`; keep only `MapCubit` tests in the app package.

---

### 12. HTTP clients never closed

- **Issue:** `GeocodingApiClient`, `RemoteZonesApiClient`, and `OpenAipZonesApiClient` default-construct `http.Client()` with no `close()` at app teardown.
- **Why:** Minor leak for a long-lived app process; VGV lifecycle hygiene.
- **Fix:** Share one `http.Client` in `bootstrap` and close in a `App` stateful wrapper `dispose`, or use `IOClient` pattern with explicit ownership.

---

### 13. Documentation drift (Photon vs Nominatim)

- **Issue:** Implementation uses Photon (`geocoding_api_client.dart`); README and `geocoding_api_client/pubspec.yaml` still say Nominatim.
- **Why:** Misleads contributors and operators about API limits/ToS.
- **Fix:** Update README architecture section and package description to Photon/komoot.

---

## 🔵 Suggestions — Nice to Have

### 14. `lib/map/view/map_page.dart:98` — `GoogleMapController?.dispose()`

- **Suggestion:** Confirm against current `google_maps_flutter` docs whether `dispose` is required or harmful; many examples omit controller disposal and rely on map widget lifecycle.

### 15. `lib/map/view/widgets/config_sheet.dart:192` — Commented-out trailing check icon

- **Suggestion:** Remove dead commented code (`// trailing: selected ? ...`).

### 16. `lib/map/view/widgets/config_sheet.dart:85` — `RangeSlider` divisions = `maxAltitude.round()`

- **Suggestion:** For `maxAltitude` 500, 500 divisions is heavy; use coarser steps (e.g. 10 m) for smoother UX.

### 17. `packages/zones_api_client/lib/src/remote_zones_api_client.dart:4–8` — Duplicate imports

- **Suggestion:** Collapse duplicate `BundledZonesApiClient` import/show lines.

### 18. Widget / golden tests

- **Suggestion:** No widget tests for `MapPage`, `ZoneDetailCard`, or `ConfigSheet`. Add focused widget tests for verdict colors/copy and locked modality UI once tap guard lands.

### 19. Package tests for API clients

- **Suggestion:** `RemoteZonesApiClient` and `OpenAipZonesApiClient` parsing deserve unit tests with fixture JSON (happy path, empty features, HTTP errors). Only `openaip_altitude_parser_test.dart` exists under `zones_api_client`.

### 20. `lib/map/google_map_style.dart` — Large embedded JSON string

- **Suggestion:** Acceptable for theming; consider asset file if editing becomes frequent.

---

## Simplicity Assessment

| Metric | Assessment |
|--------|------------|
| Lines that could be removed | ~80–120 (duplicate tests, commented UI, redundant imports, debug-only observer in release) |
| Unnecessary abstractions | Low — no spurious interfaces; layering is appropriate for app size |
| YAGNI violations | `AppBlocObserver` in production; duplicate repository test group |
| Complexity verdict | **Minor tweaks needed** in tests and `MapView` decomposition; core repository/cubit split is sound |

---

## Testing Assessment

| Area | Status |
|------|--------|
| New code with tests | **Partial** — altitude logic tested in `flight_rules_repository` package; `MapCubit` altitude paths **not** tested |
| Test quality | **Meaningful** where present (real coordinates, verdict enums, altitude skip scenarios) |
| State management test coverage | **Partial** — `MapCubit` basic; **Missing** `SettingsCubit` |
| UI component test coverage | **Missing** |
| Package data layer | **Partial** — altitude parser only; no geocoding/zones HTTP parsing tests |

**Existing test files (in scope):**

- `test/map_cubit_test.dart` — MapCubit + duplicated repository tests
- `packages/flight_rules_repository/test/flight_rules_repository_test.dart` — strong domain coverage
- `packages/zones_api_client/test/openaip_altitude_parser_test.dart` — focused parser tests

---

## Architecture & Conventions (Pass Highlights)

- **Layer direction:** Presentation imports repositories, not API clients directly (except `bootstrap` composition). ✅
- **Immutable state:** `MapState`, `SettingsState`, `FlightAssessment`, `FlyZone` use `Equatable`. ✅
- **Cubit naming:** `MapCubit`, `SettingsCubit` are descriptive. ✅
- **Repository composition:** `FlightRulesRepository.load` merges feeds with bundled fallback. ✅
- **Linting:** `very_good_analysis` with strict casts. ✅
- **Localization:** Generated l10n; domain labels extended via `localized_labels.dart`. ✅

---

## Security Notes (in scope)

- Geocoding uses public Photon (no key) — acceptable; respect third-party rate limits.
- OpenAIP key in `--dart-define` is not a server secret; treat as obfuscated client credential.
- No secrets in repository/storage code paths reviewed.
- External links via `url_launcher` use https URLs from static permit resources — low risk.

---

## Recommended merge checklist

1. Fix locked modality tap + cubit guard + test.
2. Add `MapCubit` altitude/settings tests and `SettingsCubit` tests.
3. Add `GeocodingRepository` cache tests; clarify or implement reverse cache.
4. Gate `AppBlocObserver` to debug mode.
5. Document MSL/terrain limitation in UI or improve elevation threading.
6. Remove duplicate repository tests from app `test/`.
7. Run `flutter pub get` and `very_good test -r` green before PR.
