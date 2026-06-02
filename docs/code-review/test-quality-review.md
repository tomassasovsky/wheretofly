# Test Quality Review

**Project:** `where_to_fly` (Flutter monorepo)  
**Scope:** `lib/`, `packages/*/lib/`, `packages/*/test/`, `test/`  
**Review date:** 2026-06-02

---

## Coverage Summary

| Metric | Result |
| --- | --- |
| **Test run** | **Pass** — 18 tests across 3 files (app + 2 packages) |
| **Coverage %** | **Not collected** — `flutter test --coverage` / MCP coverage output did not produce `lcov.info` in the workspace; no `min_coverage` gate in project config |
| **Estimated file coverage** | **~6%** — 3 test files vs ~50 non-generated implementation files in scope |
| **Files with tests** | **3 / ~50** testable source units |

### Missing test files (by layer)

#### State management (`lib/`)

| File | Status |
| --- | --- |
| `lib/settings/settings_cubit.dart` | **No test file** — `SettingsCubit` / `SettingsState` untested |
| `lib/map/cubit/map_cubit.dart` | **Partial** — `test/map_cubit_test.dart` covers 4 of 6 public methods; no settings integration |

#### Repositories / data clients (`packages/`)

| File | Status |
| --- | --- |
| `packages/geocoding_api_client/lib/src/geocoding_api_client.dart` | **No test file** (despite `test:` in `pubspec.yaml`) |
| `packages/geocoding_repository/lib/src/geocoding_repository.dart` | **No test file** |
| `packages/settings_repository/lib/src/settings_repository.dart` | **No test file** |
| `packages/location_repository/lib/src/location_repository.dart` | **No test file** |
| `packages/location_client/lib/src/location_client.dart` | **No test file** |
| `packages/storage/lib/src/storage.dart` | **No test file** |
| `packages/zones_api_client/lib/src/openaip_zones_api_client.dart` | **No test file** |
| `packages/zones_api_client/lib/src/bundled_zones_api_client.dart` | **No test file** |
| `packages/zones_api_client/lib/src/remote_zones_api_client.dart` | **No test file** |
| `packages/flight_rules_repository/lib/src/flight_rules_repository.dart` | **Tested** — `packages/flight_rules_repository/test/flight_rules_repository_test.dart` |
| `packages/zones_api_client/lib/src/openaip_altitude_parser.dart` | **Tested** — `packages/zones_api_client/test/openaip_altitude_parser_test.dart` |

#### Domain models (pure logic, no dedicated tests)

| File | Status |
| --- | --- |
| `packages/flight_rules_repository/lib/src/models/fly_zone.dart` | Only exercised indirectly via `assess()` |
| `packages/flight_rules_repository/lib/src/models/altitude_range.dart` | No direct tests for `clampedFor` / `clampedTo` |
| `packages/flight_rules_repository/lib/src/models/permission_level.dart` | No tests for `fromId`, `rank`, altitude ceilings |
| `packages/geocoding_api_client/lib/src/models/geocode_result.dart` | Trivial; covered when client is tested |

#### UI (`lib/map/view/`, `lib/resources/`, `lib/app/`)

| File | Status |
| --- | --- |
| `lib/map/view/map_page.dart` | **No widget tests** — search debounce, geocoding errors, location flow |
| `lib/map/view/widgets/config_sheet.dart` | **No widget tests** |
| `lib/map/view/widgets/config_bar.dart` | **No widget tests** |
| `lib/map/view/widgets/map_search_bar.dart` | **No widget tests** |
| `lib/map/view/widgets/search_results_overlay.dart` | **No widget tests** |
| `lib/map/view/widgets/zone_detail_card.dart` | **No widget tests** — verdict / zone list UI |
| `lib/map/view/widgets/map_legend.dart` | **No widget tests** |
| `lib/map/view/widgets/settings_sheet.dart` | **No widget tests** |
| `lib/resources/view/resources_page.dart` | **No widget tests** |
| `lib/app/app.dart` | **No widget tests** |

**Excluded from “missing” (generated or thin):** `lib/l10n/gen/*`, `lib/main.dart`, `lib/bootstrap.dart` (optional smoke test only).

---

## State Management Test Quality

### `test/map_cubit_test.dart` — **Issues found**

**Strengths**

- Uses `bloc_test` and `flutter_test` correctly for a Flutter cubit.
- Covers happy-path reassessment when permission, modality, and point change.
- Uses real `FlightRulesRepository` with known geographic fixtures (Plaza de Mayo, Aeroparque, open sea) — good integration signal.

**Gaps**

| Method / behavior | Covered? |
| --- | --- |
| `checkPoint` | Yes |
| `selectPermission` | Yes |
| `selectModality` | Yes |
| `selectAltitudeRange` | **No** — altitude is core to flight verdicts |
| `clearSelection` | **No** |
| Initial state from `SettingsRepository` | **No** — `permissionId`, `modalityId`, `flightAltitudeRangeAgl`, clamping |
| `_persistAltitude` / settings writes on permission change | **No** |

**Structural issue:** The file’s first `group('FlightRulesRepository', …)` duplicates four scenarios already covered (and extended) in `packages/flight_rules_repository/test/flight_rules_repository_test.dart`. The package tests add altitude overlap cases the app tests omit. Keeping both creates maintenance drift (e.g. wording differs: “blocked” vs “requires authorization”).

**Pattern note:** All `blocTest` cases use `verify:` only and never `expect:` on emitted states. That checks the final cubit state after `act` but not emission count or intermediate states. Acceptable for simple cubits, but weaker if regressions emit extra states.

```dart
blocTest<MapCubit, MapState>(
  'selectModality re-evaluates the current selection',
  build: () => MapCubit(repository),
  act: (cubit) => cubit..checkPoint(...)..selectModality(...),
  verify: (cubit) { /* assertions on cubit.state */ },
);
```

**Recommendation:** Add `expect: () => [isA<MapState>(), …]` where reassessment should emit exactly one update, and use a `MockSettingsRepository` (mocktail is already in `pubspec.yaml` but unused) for persistence tests.

### `lib/settings/settings_cubit.dart` — **Missing tests**

No `test/settings_cubit_test.dart`. Required coverage:

- Initial state maps `SettingsRepository` locale + theme.
- `setLanguage(null)` clears locale (`clearLocale: true`).
- `setLanguage('es')` persists and emits `Locale('es')`.
- `setThemeMode` round-trip with `AppThemeMode` mapping.

Use `bloc_test` + mocktail `MockSettingsRepository` (or in-memory fake `Storage`).

---

## Repository & Package Test Quality

### `packages/flight_rules_repository/test/flight_rules_repository_test.dart` — **Pass (strongest suite)**

**Strengths**

- Spec-style names tied to regulation scenarios.
- Uses `FlightRulesRepository.fromZoneData` for isolated altitude fixtures — excellent pattern.
- Covers `skippedByAltitude`, mid-band overlap, and MSL floor exclusion — behavior that directly affects user safety messaging.

**Gaps**

| Area | Risk |
| --- | --- |
| `FlightRulesRepository.load` | Untested — merge by id, `_safe` swallowing errors, bundled fallback |
| `FlyZone.contains` / `overlapsAltitudeRange` | No direct unit tests — haversine boundary bugs would only surface via integration |
| `zonesAt` / `zonesAtAltitude` | Untested public helpers |

### `packages/zones_api_client/test/openaip_altitude_parser_test.dart` — **Pass (narrow)**

**Strengths**

- Tests GND vs MSL datum behavior and conservative default when limits missing.

**Gaps**

- No tests for string limits (`GND`, `UNL`, `3000FT AMSL`), `_parseLimit` map shapes, or feet→meters conversion edge cases.
- No tests for `OpenAipZonesApiClient` polygon→circle approximation, `_categoryFor` (CTR/TMA/SAR naming), excluded type filtering, or `maxRadiusMeters` drop — **high regulatory impact**.

### Untested network / persistence layers — **Critical gap**

**`GeocodingApiClient`**

- Photon response parsing (`_parseFeature`, `_formatLabel`, Argentina bbox filter).
- Failure mapping: transport error → `GeocodingFailure.network`, empty features → `noResults`.
- Non-AR `countrycode` rejection.

**`GeocodingRepository`**

- Cache write on successful search.
- Offline fallback: network exception returns cached result.
- `reverse` passthrough (currently untested).

**`SettingsRepository`**

- `flightAltitudeRangeAgl` legacy key migration (`_altitudeLegacyKey`).
- Invalid stored values → defaults.
- `min > max` correction branch.

These should use `mocktail` + `package:http` `MockClient` or injected fakes, matching VGV data-layer conventions.

---

## UI Component Test Quality

**No widget tests exist** in `test/` or package `test/` folders.

For a safety-oriented map app, minimum widget coverage should include:

1. **`ZoneDetailCard`** — renders `FlightVerdict.allowed`, `notAllowed`, `allowedWithPermission`; shows blocking zones vs empty.
2. **`ConfigSheet` / `ConfigBar`** — selecting permission/modality/altitude dispatches cubit callbacks (with `BlocProvider` + mock cubit or `MockMapCubit` via `mocktail` when using `Cubit` — prefer real `MapCubit` with fake repository).
3. **`MapPage` search UX** — debounce, error banner for `GeocodingFailure`, empty results (can pump with mocked `GeocodingRepository`).

`google_maps_flutter` complicates full `MapPage` tests; extract search/overlay subtree into testable widgets or use `GoogleMap` mocking patterns (platform channel fakes) for focused tests.

---

## Anti-Patterns Found

| Location | Anti-pattern | Issue | Fix |
| --- | --- | --- | --- |
| `test/map_cubit_test.dart:9–66` | **Duplicate test suite** | Same `FlightRulesRepository` scenarios as package test; package version is strictly better | Remove repository group from app test; keep only `MapCubit` group |
| `pubspec.yaml` + all tests | **Unused mocktail** | Dependency declared, zero `Mock` classes — settings/geocoding tests cannot isolate I/O | Add mocks for `SettingsRepository`, `GeocodingApiClient`, `http.Client` |
| `test/map_cubit_test.dart` blocTests | **Verify-only bloc tests** | No `expect` on state sequence | Add `expect` where emission count matters |
| N/A (missing tests) | **False confidence via integration only** | Core geometry (`FlyZone.contains`) not unit-tested | Add focused `fly_zone_test.dart` with known radius edge cases |

No tautological assertions (`expect(true, isTrue)`) or empty tests were found in existing files.

---

## Quality Signals (existing tests)

| File | Success | Failure / edge | Assertions | Names |
| --- | --- | --- | --- | --- |
| `flight_rules_repository_test.dart` | Yes | Prohibited, controlled, altitude skip | Meaningful verdict/zone lists | Spec-style |
| `openaip_altitude_parser_test.dart` | Yes | Missing limits, MSL floor | `appliesAt` behavior | Clear |
| `map_cubit_test.dart` | Yes | Prohibited point | Final state only | Good for cubit |

---

## Recommendations (priority order)

1. **Add `test/settings_cubit_test.dart`** with mocktail-backed `SettingsRepository` — unblocks theme/locale regressions.
2. **Extend `map_cubit_test.dart`** (or split `map_cubit_settings_test.dart`) for `selectAltitudeRange`, `clearSelection`, and hydrated initial state from settings; remove duplicate `FlightRulesRepository` group.
3. **Add `packages/geocoding_api_client/test/geocoding_api_client_test.dart`** with `MockClient` and fixture JSON bodies for search/reverse.
4. **Add `packages/geocoding_repository/test/geocoding_repository_test.dart`** for cache fallback on network failure.
5. **Add `packages/zones_api_client/test/openaip_zones_api_client_test.dart`** with minimal airspace JSON fixtures for `_parse` and category mapping.
6. **Add `packages/flight_rules_repository/test/fly_zone_test.dart`** for `contains` and `overlapsAltitudeRange` boundaries.
7. **Add widget tests** for `ZoneDetailCard` and config UI (highest user-visible risk).
8. **Wire CI** — `very_good test --recursive --coverage --min_coverage 80` (or staged ramp-up) once baseline improves.

---

## Verdict

**Fix 8+ issues before merging** — existing tests are well-written where they exist, but coverage is far below VGV’s non-negotiable bar for a production safety app. The domain repository and altitude parser tests are a solid foundation; the presentation layer, settings, geocoding, and OpenAIP ingestion paths are effectively untested and are the highest regression risk.
