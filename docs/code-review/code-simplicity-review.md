# Code Simplicity Review — `where_to_fly`

Scope: `lib/`, `packages/*/lib/`, `backend/lib/`. Excluded: generated files
(`**/*.g.dart`, `lib/l10n/gen/**`), `tooling/**`, vendored assets, `docs/**`.

Approximate in-scope size: `lib/` ~12.0k LOC, `packages/*/lib` ~8.6k LOC
(of which `argentina_bounds` ~4.9k is generated coordinate data), `backend/lib`
~3.3k LOC.

## Core Purpose

`where_to_fly` is a Flutter map app that shows drone/paraglider fly zones over
Argentina, an Open-Meteo wind-gust overlay, geocoding search, and a (currently
hidden) social/messaging layer, backed by a Dart Frog API. The bulk of the
real complexity lives in the map + wind subsystem; the rest is conventional
VGV-layered plumbing (api_client → repository → cubit → view).

Overall the codebase is clean, consistently structured, and well-commented. The
main simplicity problems are **dead code and dormant features left in the
tree**, plus a few **passthrough indirection layers** that add hops without
behavior. There is no pervasive over-engineering.

---

## Critical

### C1. Wind-direction arrows: ~550 LOC dormant behind a compile-time `false`

`WindMapConfig.arrowsEnabled` is a hard-coded `static const arrowsEnabled = false`
(`lib/map/wind_map_config.dart:15`). It is read in exactly one place:

```275:282:lib/map/view/widgets/flutter_map_layer.dart
              if (widget.showWindLayer &&
                  _windLayerRetained &&
                  WindMapConfig.arrowsEnabled)
                WindDirectionOverlay(
                  mapController: _mapController,
                  data: _windTileProvider.data,
                  brightness: widget.brightness,
                ),
```

Because the flag is a `const false`, `WindDirectionOverlay` is never built. The
entire arrow pipeline it pulls in is effectively dead today:

- `lib/map/wind/wind_direction_overlay.dart` (211)
- `lib/map/wind/wind_arrow_painter.dart` (83)
- `lib/map/wind/om/wind_arrow_math.dart` (235)
- `lib/map/wind/om/wind_vector_tile.dart` (16)
- the `wind_u_component_10m` / `wind_v_component_10m` sampling paths in
  `open_meteo_wind_data.dart`, `om_spatial_url.dart`, and `dwd_icon_grid.dart`.

That is **~550+ LOC of complex, math-heavy, untested-in-production code** kept
alive only to be skipped. The comment says "off until performance is ready,"
but dormant code is still a maintenance and review liability.

**Recommendation:** either (a) delete the arrows feature and recover it from
git when performance work begins, or (b) if it must stay, move it behind a
runtime `bool.fromEnvironment` flag so at least the dead-on-arrival `const false`
is honest, and add a tracking issue. Option (a) is the simplest.

### C2. Social + messaging features (~2.9k LOC) gated off by `AppMode.mapOnly`

```1:5:lib/app/app_mode.dart
/// Product scope toggles while features roll out incrementally.
abstract final class AppMode {
  /// When true, only the map is exposed; social tabs redirect to the map.
  static const mapOnly = true;
}
```

`mapOnly` is a `const true`, so every `if (AppMode.mapOnly)` branch is always
taken and every `!AppMode.mapOnly` branch is dead. There are 13 references
across the router, shell, settings, splash, auth navigation, and
`zone_detail_card`, each carrying a currently-unreachable counterpart path. The
gated-off `lib/social/` + `lib/messaging/` UI (~2.9k LOC), plus their cubits,
repositories, and api_clients, ship but never run.

This is the single largest YAGNI surface in the project. It is clearly
intentional ("features roll out incrementally"), so this is a flag, not a
demand:

**Recommendation:** Don't carry a full hidden product indefinitely. Either
commit to a near-term rollout, or remove social/messaging (and their packages)
from the build and restore from git when scheduled. At minimum, the dead
`!AppMode.mapOnly` UI branches in shared files (e.g. `zone_detail_card.dart`,
`settings_page.dart`, `app_shell.dart`) add cognitive load to map-only code
that is shipping today.

---

## Important

### I1. Dead imperative API on `MapCameraController` (~60 LOC)

`lib/map/map_camera_controller.dart` exposes several methods that nothing calls
(verified across `lib/`):

- `readCamera()` (lines 52–64) — unused. Its sole return type
  `MapCameraSnapshot` (`lib/map/map_camera_snapshot.dart`, 12 lines) is therefore
  **entirely dead** — the class is referenced only by this dead method.
- `visibleBounds()` (lines 108–119) — unused; `flutter_map_layer.dart` builds
  `MapVisibleBounds` directly from `camera.visibleBounds` instead.
- `panByPixels()` (lines 68–80) — unused.
- `latLngForScreenOffset()` (lines 82–89) — unused.

These look like leftovers from the MapLibre-GL-JS era (the deleted
`assets/wind_map/*.js` in git status). Removing them deletes ~60 LOC plus the
`map_camera_snapshot.dart` file.

### I2. Dead `mapTileTemplateFor` + its only-purpose passthrough

`MapInitializer.mapTileTemplateFor` (`map_initializer.dart:36`) has **zero
callers**. Its body delegates to `MapTheme.tileUrlTemplateFor`, which in turn
*only* exists to delegate to `MapConfig.tileUrlTemplateFor` and has no other
caller. So both the method and the `MapTheme` wrapper are dead. Delete
`MapInitializer.mapTileTemplateFor` and `MapTheme.tileUrlTemplateFor`; callers
already use `MapConfig.tileUrlTemplateFor` directly.

### I3. Dead "legacy" layout constants

```21:25:lib/map/map_layout.dart
  static const bottomChromeHeight =
      configBarContentHeight + configBarBottomPadding;

  /// Legacy name: camera/FAB inset when safe area is zero (~80px).
  static const bottomOverlayInset = bottomChromeHeight + fabAboveConfigBar + 38;
```

Both `bottomChromeHeight` and `bottomOverlayInset` are defined but referenced
nowhere outside this file. The comments even label them "Legacy name." Delete.

### I4. Triple-hop facade: `MapInitializer` → `MapTheme` → `MapConfig`

`MapInitializer` is largely a thin facade over `MapTheme`/`MapConfig`/`ArgentinaBounds`:

- `placeholderColorFor` → `MapTheme.placeholderFor` (single passthrough)
- `mapTileTemplateFor` → `MapTheme.tileUrlTemplateFor` → `MapConfig...` (dead, see I2)
- `initializePlatform()` → `async {}` no-op

Likewise `MapTheme.tileUrlTemplateFor` adds a hop to `MapConfig`. These layers
were presumably useful when a native map plugin needed initialization; with
flutter_map they mostly forward calls. Collapse `MapInitializer`/`MapTheme` into
direct `MapConfig` use (and inline the one-line placeholder helper at its single
call site in `map_view.dart:145`).

### I5. Pure-passthrough repositories

Several repositories contain **no logic** — every method is a one-liner forward
to the api_client:

- `packages/location_repository` (23 LOC) — `currentLocation()` → client.
- `packages/weather_repository` (37 LOC) — all 4 methods forward.
- `packages/messaging_repository` (42 LOC) — all 8 methods forward.
- `packages/social_repository` (62 LOC) — all methods forward.

This is the VGV layered pattern, so it is defensible as a stable seam. But these
add an entire package + DI wiring + test scaffolding for zero behavior. By
contrast `geocoding_repository` and `auth_repository` earn their layer (caching,
session refresh). Consider letting cubits depend on the api_client directly for
the pure-passthrough cases, or at least acknowledge these are seams-only. (Note:
`messaging`/`social` repos are part of the C2 dormant feature set anyway.)

---

## Suggestions

- **`disposeNative()` redundant wrapper** (`map_camera_controller.dart:34-39`):
  its whole body is `clearNativeController()`. The caller could call
  `clearNativeController()` directly, or keep one of the two names.
- **`MapZoneOverlayBuilder.selectedPoint(state)`** (`map_zone_overlay_builder.dart:50`)
  is `=> state.selectedPoint`. Its single caller can read `state.selectedPoint`
  directly; the wrapper adds nothing.
- **`MapInitializer.initializePlatform()`** is an `async {}` no-op awaited in
  `bootstrap.dart:54`. Remove the call and the method unless a real init is
  imminent.
- **Duplicated `PlaceNameDisplay`** in `lib/core/place_name_display.dart` and
  `backend/lib/util/place_name_display.dart` (same Malvinas substitutions). This
  is cross-tier (no shared package), so duplication is acceptable, but a shared
  pure-Dart package would remove the drift risk if these grow.
- **`ZoneSyncService`** (`lib/zone_sync/zone_sync_service.dart`, 17 LOC) is a
  thin wrapper over `FlightRulesRepository.load`. Fine to keep for DI, but it
  and `map_zone_sync.dart` (a 15-LOC helper fn) could be one small unit.
- **`MapVisibleBounds`** mirrors flutter_map's `LatLngBounds` (sw/ne only). It
  usefully keeps `MapZoneDisplay` free of a flutter_map import, so keep it —
  unlike `MapCameraSnapshot` (I1), it is actually used.

---

## YAGNI Violations (summary)

- Wind-direction arrows shipped but `const`-disabled (C1).
- Full social/messaging product shipped but `const`-disabled (C2).
- MapLibre-era imperative camera API kept after the flutter_map migration (I1).
- Facade/passthrough layers (`MapInitializer`, `MapTheme`, pure repos) that add
  hops without behavior (I2, I4, I5).

## Final Assessment

- **Realistically removable now (low risk):** ~700+ LOC — dormant arrows (C1),
  dead camera API + snapshot (I1), dead tile/layout helpers (I2, I3), and the
  passthrough collapses (I4). That is roughly a **6% reduction of in-scope
  non-generated code** with no behavior change.
- **Potentially removable (product decision):** the ~2.9k-LOC social/messaging
  stack (C2).
- **Complexity score:** Low–Medium. The architecture is sound and idiomatic;
  the issue is accumulated dead/dormant code from feature flags and a map-engine
  migration, not bad design.
- **Recommended action:** Proceed with the C1/I1–I4 deletions (mechanical, safe,
  test-covered seams). Make an explicit product call on C2 and the
  pure-passthrough repositories rather than carrying them indefinitely.
