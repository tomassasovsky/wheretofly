---
title: refactor: deconstruct map page into layered architecture
type: refactor
date: 2026-06-03
---

## refactor: deconstruct map page into layered architecture

## Overview

The map screen's entry file (`lib/map/view/map_page.dart`) is a **643-line monolith** at `HEAD` that mixes four concerns in one file: dependency injection, cross-cubit orchestration, Google Maps platform control, and overlay layout. This refactor splits it into a thin **Page → View → Widget** presentation tree while keeping business logic in existing cubits and pushing pure map/zone rendering into testable utilities.

**Status:** Complete (2026-06-03)

| Delivered | Notes |
|-----------|-------|
| `map_page.dart` slimmed to providers + listeners (~79 lines) | Includes auth→weather refetch |
| `map_view.dart`, `map_search_listeners.dart`, extracted widgets | Presentation split |
| `map_zone_sync.dart`, `map_zone_overlay_builder.dart`, `map_layout.dart` | Utilities |
| Tests: overlay builder, search listeners, layout, initializer, map page smoke | See `test/map_*` |

## Problem Statement / Motivation

### What the monolith contains today

At `HEAD`, `map_page.dart` bundles:

```
643 lines total
├── Helpers (15 lines)
│   ├── _toGoogle / _fromGoogle
│   └── _syncZonesFromBackend
├── MapPage (~50 lines)          ← providers + cross-feature listeners
├── MapView + _MapViewState (~430 lines)
│   ├── GoogleMapController lifecycle
│   ├── Search TextEditingController / FocusNode
│   ├── Camera: move, zoom, visible bounds
│   ├── Overlay builders: _circles, _markers
│   ├── Search side-effect listeners (MultiBlocListener)
│   └── Stack layout (map + search + FABs + detail + banner + config)
├── _ZoneDetailOverlay (~25 lines)
├── _MapFabColumn (~40 lines)
└── _ZoomControls (~35 lines)
```

### Why this violates layered architecture

| Violation | Location | Correct layer |
|-----------|----------|---------------|
| Zone circle/marker construction mixed with widget state | `_circles`, `_markers` in `_MapViewState` | Pure utility (`map_zone_overlay_builder.dart`) |
| Google Maps controller + camera imperatives in view state | `_controller`, `_moveCamera`, `_zoomBy` | Dedicated widget (`map_google_layer.dart`) |
| Search cubit side effects (snackbars, camera navigation) inline in `build` | `MultiBlocListener` inside `MapView.build` | Listener widget (`map_search_listeners.dart`) |
| Layout magic numbers duplicated | `_topOverlayInset`, `_bottomOverlayInset` | Shared constants (`map_layout.dart`) |
| Private widgets defined at file bottom | `_MapFabColumn`, `_ZoomControls`, `_ZoneDetailOverlay` | `lib/map/view/widgets/` |

Business logic is **already well-factored** in `MapCubit`, `MapSearchCubit`, and `MapWeatherCubit`. The problem is presentation-layer bloat, not missing repositories.

## Decisions

These were open questions from flow analysis; defaults below keep scope minimal:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Theme change camera | **Preserve** position and selection | Match monolith; never remount `GoogleMap` on brightness change |
| Theme source | **`SettingsCubit.themeMode`** | Aligns with `MapPrewarmHost`; intentional improvement over `Theme.of(context).brightness` |
| Zone sync failure UI | **Silent** (no snackbar) | Same as monolith; bundled zones remain usable |
| Duplicate sync on cold start | **Allow** (initState + auth listener) | Idempotent network call; no dedupe flag unless profiling shows harm |
| Weather after login with open card | **Refetch** | Add `MapPage` listener on auth transition when `selectedPoint != null` |
| Weather race on rapid taps | **Last response wins** | No in-flight cancellation (monolith behavior) |
| Lat/lng conversion file | **Inline in overlay builder** | Two one-liners do not warrant a separate file |

## Out of scope

Do **not** change during this refactor:

- `MapCubit`, `MapSearchCubit`, `MapWeatherCubit` logic (unless a compile fix requires a signature tweak)
- Repository or API client packages
- Existing widgets: `ConfigBar`, `ZoneDetailCard`, `MapSearchBar`, `SearchResultsOverlay`, `ZoneStaleBanner`, `MapLegend`, `ConfigSheet`
- `MapZoneDisplay` culling rules
- `ZoneSyncService` or backend sync behavior
- New packages or barrel files (project has no `lib/map.dart` barrel today)

## Proposed Solution

### Target file structure

```text
lib/map/
├── cubit/                          # Business logic (unchanged)
│   ├── map_cubit.dart
│   ├── map_search_cubit.dart
│   └── map_weather_cubit.dart
├── map_initializer.dart            # Platform + theme helpers (exists)
├── map_layout.dart                 # Overlay inset constants (new)
├── map_zone_display.dart           # Zone culling/styling rules (exists)
├── map_zone_overlay_builder.dart   # circles + markers from MapState (new)
├── map_zone_sync.dart              # Auth-triggered zone pull (exists)
├── view/
│   ├── map_page.dart               # Providers + cross-cubit listeners only
│   ├── map_view.dart               # Layout orchestration (minimal state)
│   ├── map_search_listeners.dart   # Search cubit side effects
│   └── widgets/
│       ├── map_google_layer.dart   # GoogleMap + controller + culling state
│       ├── map_search_header.dart  # Search bar + results + legend column
│       ├── map_fab_column.dart     # Legend / zoom / locate FABs (extracted)
│       ├── map_zoom_controls.dart  # +/- pill (extracted)
│       ├── map_zone_detail_overlay.dart  # AnimatedSize wrapper (extracted)
│       └── … (existing widgets unchanged)
```

### Layer responsibilities

```text
┌─────────────────────────────────────────────────────────┐
│ Presentation — lib/map/view/                            │
│  MapPage: MultiBlocProvider + cross-feature listeners   │
│  MapView: Stack layout, local UI state (_showLegend)    │
│  Widgets: dumb/reusable UI + map platform layer         │
└──────────────────────────┬──────────────────────────────┘
                           │ reads/dispatches
┌──────────────────────────▼──────────────────────────────┐
│ Business Logic — lib/map/cubit/                         │
│  MapCubit, MapSearchCubit, MapWeatherCubit             │
└──────────────────────────┬──────────────────────────────┘
                           │ calls
┌──────────────────────────▼──────────────────────────────┐
│ Repository — packages/*_repository/                     │
│  FlightRules, Geocoding, Location, Weather, Settings    │
└──────────────────────────┬──────────────────────────────┘
                           │ calls
┌──────────────────────────▼──────────────────────────────┐
│ Data — packages/*_api_client/                           │
└─────────────────────────────────────────────────────────┘

Pure utilities (lib/map/*.dart, no Flutter widgets):
  MapZoneDisplay, MapZoneOverlayBuilder, MapInitializer
```

### Page / View / Widget contract

**`MapPage`** — only wiring, no layout:

- Provides `MapCubit`, `MapSearchCubit`, `MapWeatherCubit`
- Listens: `selectedPoint` → `MapWeatherCubit.fetchFor` / `clear`
- Listens: auth false→true → `syncMapZonesFromBackend`
- Listens: auth false→true with open `selectedPoint` → `MapWeatherCubit.fetchFor`
- Child: `const MapView()`

**`MapView`** — orchestrates layout, owns search controllers:

- `TextEditingController`, `FocusNode`, `_showLegend`
- Delegates search side effects to `MapSearchListeners`
- Composes `Stack` from extracted widgets
- Reads `SettingsCubit` for theme → passes `Brightness` to `MapGoogleLayer`
- InitState: sync zones if already authenticated (cold start)

**`MapGoogleLayer`** — owns platform map state:

- `GoogleMapController` lifecycle + safe dispose
- Tracks `_zoom`, `_visibleBounds` for zone culling
- Exposes `MapGoogleLayerController` (held by parent via `final controller = MapGoogleLayerController()`):

```dart
class MapGoogleLayerController {
  void attach(GoogleMapController native);
  void detach();
  Future<void> moveTo(LatLng target, {required double zoom});
  Future<void> zoomBy(double delta);
}
```

- `attach`/`detach` called from `MapGoogleLayer.onMapCreated` / `dispose`; parent methods no-op when detached
- Builds circles/markers via `MapZoneOverlayBuilder`
- Uses `MapInitializer` for camera defaults, style, color scheme
- Passes `MapInitializer.mapStyleFor(brightness)` and `mapColorSchemeFor(brightness)` on each build — **no** `ValueKey(brightness)`

**`MapSearchListeners`** — side effects only, no layout:

- `resolvedAddressLabel` → write search field, clear label
- `focusPoint` → camera move + optional assessment via callback
- `locationFailure` / `outsideArgentina` → localized snackbar

## Technical Considerations

### Preserve monolith behavior unless explicitly improved

| Topic | Monolith behavior | Refactor note |
|-------|-------------------|---------------|
| Theme source | `Theme.of(context).brightness` | **Intentional change:** use `SettingsCubit.themeMode` via `MapInitializer.mapBrightnessFor` (matches `MapPrewarmHost`) |
| Theme toggle camera | Map widget not remounted | **Risk:** avoid `ValueKey(brightness)` on `GoogleMap` — update `style`/`colorScheme` in place to preserve camera |
| Zone sync failure | Silent catch, bundled zones remain | Keep silent; document in AC |
| Weather race on rapid taps | Last response wins | Keep current behavior; no cancellation |
| Duplicate zone sync | initState + auth listener may overlap | Allow idempotent double-call (see Decisions) |

### Cross-cubit coordination stays in `MapPage`

Per VGV conventions, repositories must not import each other; combining auth + weather + zones at the **page listener** level is correct. Do not introduce a god-coordinator cubit unless complexity grows further.

### `ZoneSyncService.lastMetadata` is not listenable

`ZoneStaleBanner` reads metadata imperatively. After sync, ensure a parent rebuild occurs (e.g., `MapCubit.updateZones` emit already triggers `BlocBuilder<MapCubit>`). Verify banner updates in manual QA.

### Dependencies

- Existing packages unchanged: `flight_rules_repository`, `geocoding_repository`, `location_repository`, `weather_repository`, `settings_repository`, `auth_repository`
- `google_maps_flutter`, `latlong2` remain app-level (presentation + utilities)

## Implementation Tasks

> **Compile note:** The working tree already imports `map_view.dart` but the file is missing. Land Phases 1–5 in one pass (or revert the `map_page.dart` import until Phase 5) so the app never sits in a broken state.

### Phase 1 — Pure utilities (no widgets)

- [ ] **1.1** Create `lib/map/map_layout.dart` with `topOverlayInset` (76.0) and `bottomOverlayInset` (108.0)
- [ ] **1.2** Create `lib/map/map_zone_overlay_builder.dart`:
  - Private `toGoogle` / `fromGoogle` helpers (from monolith)
  - `static Set<Circle> circles(MapState, {bounds, zoom, isDark})`
  - `static Set<Marker> markers(MapState)`
  - Delegate culling/styling to `MapZoneDisplay`
- [ ] **1.3** Run existing `test/map_zone_overlay_builder_test.dart` — must pass before Phase 2

### Phase 2 — Extract private widgets

- [ ] **2.1** Create `widgets/map_zoom_controls.dart` from `_ZoomControls`
- [ ] **2.2** Create `widgets/map_fab_column.dart` from `_MapFabColumn` (uses `MapZoomControls`)
- [ ] **2.3** Create `widgets/map_zone_detail_overlay.dart` from `_ZoneDetailOverlay` (wraps existing `ZoneDetailCard`)
- [ ] **2.4** Create `widgets/map_search_header.dart` — column with `MapSearchBar`, `SearchResultsOverlay`, conditional `MapLegend`

### Phase 3 — Map platform layer

- [ ] **3.1** Create `widgets/map_google_layer.dart`:
  - `MapGoogleLayerController` class (`moveTo`, `zoomBy`, attach/detach)
  - Stateful widget owning controller, zoom, visible bounds
  - `onTap(LatLng)`, `padding`, `brightness`, `state: MapState`
  - **Do not** use `ValueKey(brightness)` — update style via `GoogleMap.style` rebuild
- [ ] **3.2** Move `_updateVisibleRegion`, `_zoomBy`, `_moveCamera` logic into this widget/controller

### Phase 4 — Search side effects

- [ ] **4.1** Create `view/map_search_listeners.dart`:
  - Wraps child with three `BlocListener<MapSearchCubit, …>`
  - Constructor: `searchController`, `searchFocusNode`, `mapController`, `onCheckPoint`, `child`
  - Private `_goToPoint` + `_locationErrorMessage` moved here
- [ ] **4.2** Port `_onSearchFocusChanged`, query/submit handlers to `MapView` (thin callbacks)

### Phase 5 — View + page assembly

- [ ] **5.1** Create `view/map_view.dart` (~120–180 lines target):
  - Owns search controllers + `_showLegend`
  - `MapSearchListeners` → `Scaffold` → `Stack` of extracted widgets
  - Uses `MapLayout` insets throughout
- [ ] **5.2** Finalize `view/map_page.dart`:
  - Verify imports compile; no map/camera code remains
  - Add auth→weather refetch listener (see Decisions)
- [ ] **5.3** Run `flutter analyze` — app must compile

### Phase 6 — Tests

- [ ] **6.1** `test/map_zone_overlay_builder_test.dart` — already written; verify green
- [ ] **6.2** `test/map_search_listeners_test.dart` — mock cubits; assert `focusPoint` invokes camera callback; assert location snackbar text
- [ ] **6.3** `test/map_view_test.dart` — smoke: `MapPage` renders `Scaffold` + map chrome under mocked providers
- [ ] **6.3b** `test/map_layout_test.dart` — layout inset constants
- [ ] **6.4** Re-run full test suite + analyzer

> **Test scope:** Do not widget-test `MapGoogleLayer` directly (platform view). Coverage comes from overlay builder unit tests + search listener tests + manual map QA.

## Acceptance Criteria

### Architecture

- [ ] `map_page.dart` ≤ 100 lines; contains only `MultiBlocProvider`, `MultiBlocListener`, and `MapView`
- [ ] No `google_maps_flutter` imports in `map_page.dart`
- [ ] Zone circle/marker logic lives only in `map_zone_overlay_builder.dart`
- [ ] No private widget classes remain in page/view files — all in `widgets/`

### Flow 1 — Map tap → assessment + weather

- [ ] Tap shows marker, detail card, correct verdict
- [ ] Weather: loading → loaded (authed) or `requiresAuth` (guest)
- [ ] Reverse geocode updates search bar; failure shows coordinate fallback

### Flow 2 — Search

- [ ] Query &lt; 2 chars: no results panel
- [ ] Debounced search; stale responses ignored
- [ ] Select result: camera zoom 12, assessment shown, short label in field
- [ ] Non-empty query typing clears open detail card

### Flow 3 — Locate me

- [ ] FAB disabled while `locating`
- [ ] Inside Argentina: zoom 12 + assessment
- [ ] Outside Argentina: zoom 5 + snackbar
- [ ] Permission/service errors show localized snackbar

### Flow 4 — Auth zone sync

- [ ] Cold start (already authed): sync runs, zones update
- [ ] Login transition: sync runs; open selection reassessed via `MapCubit.updateZones`
- [ ] Sync failure: bundled zones remain, no crash
- [ ] Login with open detail card refetches weather (authed)

### Flow 5 — Config changes

- [ ] Permission/modality/altitude reassess without clearing selection
- [ ] Locked modalities cannot be selected

### Flow 6 — Clear selection

- [ ] Close clears search, weather, marker, detail card
- [ ] Search focus clears selection

### Flow 7 — Legend / zoom

- [ ] Legend toggles without affecting selection
- [ ] Zoom +/- updates visible zone set per `MapZoneDisplay` rules

### Flow 8 — Stale banner

- [ ] Hidden when metadata empty or &lt; 7 days old
- [ ] Shown with version when stale

### Flow 9 — Theme

- [ ] Light: default style; dark: `GoogleMapStyle.darkJson`
- [ ] `ThemeMode.system` follows platform brightness
- [ ] **Theme toggle preserves camera position and selection** (no full map remount)

### Regression guards

- [ ] `MapLayout` insets unchanged (search, FABs, attribution clearance)
- [ ] Highlight includes `assessment.skippedByAltitude` zone IDs
- [ ] `PlatformException` during navigation/dispose does not crash
- [ ] `flutter analyze` clean; all tests pass

## Success Metrics

- `map_page.dart` line count reduced from **643 → ~75** (page only)
- Largest new file (`map_google_layer.dart` or `map_view.dart`) stays **under 200 lines**
- Zero analyzer warnings in `lib/map/`
- New unit/widget tests cover overlay builder and search listeners

## Dependencies & Risks

| Risk | Mitigation |
|------|------------|
| `map_view.dart` missing — app broken now | Complete Phases 1–5 in one pass; see compile note above |
| Theme remount resets camera | Explicit AC; no `ValueKey` on map |
| Controller null before `onMapCreated` | FAB/search no-op until ready (same as monolith) |
| Widget test fragility with GoogleMap | Test listeners/utilities; smoke-test view with fakes |

## References & Research

- Monolith source: `lib/map/view/map_page.dart` at `HEAD` (643 lines)
- Existing cubits: `lib/map/cubit/map_cubit.dart`, `map_search_cubit.dart`, `map_weather_cubit.dart`
- Zone culling: `lib/map/map_zone_display.dart`
- Platform init: `lib/map/map_initializer.dart`, `lib/map/view/map_prewarm.dart`
- VGV layered architecture: Presentation → Cubit → Repository → Data
- Partial WIP: `map_zone_sync.dart`, slim `map_page.dart`, `test/map_zone_overlay_builder_test.dart`
