# Architecture Review — `where_to_fly`

**Reviewer:** Architecture Review Agent (VGV layered-architecture standards)
**Scope:** Full project — `lib/` (presentation + business logic), `packages/*/` (data + repository layers), and `backend/` (Dart Frog API) as a separate package.
**Excluded:** generated files (`**/*.g.dart`, `lib/l10n/gen/**`), `tooling/**`, vendored assets, `docs/**`.

## Summary

The project follows the VGV layered architecture quite faithfully at the **package** level: the dependency graph is clean and one-directional, there are no circular dependencies, every package has a proper manifest/lints/tests, and state management is textbook (immutable `Equatable` states, `copyWith`, business logic in cubits, providers wired at a single composition root).

The weak point is the **layer boundary between presentation and data**. Several repositories pass data-layer models and exceptions straight through instead of exposing domain types or re-exporting them, which forces the presentation layer — including pure UI widgets — to `import 'package:*_api_client/...'` directly. The data *flow* still goes through repositories (so behavior is correct), but the *type/exception coupling* repeatedly crosses the layer boundary, and in the worst cases UI widgets depend on the data layer with no repository in between.

The backend is cleanly layered (`routes → services → db`) with a singleton DI container.

---

## Layer Separation

VGV layers in this project: **data** (`*_api_client`, `storage`, `location_client`) ← **repository** (`*_repository`) ← **business logic** (`lib/**/cubit`, `lib/**/*_cubit.dart`) ← **presentation** (`lib/**/view`). Per the README, repository packages "never import Flutter" and each layer talks only to the one beneath it.

### Violations

#### 1. Presentation UI widgets import the data layer directly (Critical)

These files live in the presentation layer (`view/`) yet import `*_api_client` packages, skipping both the repository and business-logic layers:

- `lib/map/view/widgets/zone_stale_banner.dart:3` — imports `package:zones_api_client` for `ZoneFeedMetadata`
- `lib/social/view/widgets/post_card.dart:2` — imports `package:social_api_client`
- `lib/social/view/widgets/post_media_view.dart:6` — imports `package:social_api_client`
- `lib/social/view/widgets/profile_media_grid.dart:2` — imports `package:social_api_client`
- `lib/social/view/widgets/reel_feed_item.dart:2` — imports `package:social_api_client`
- `lib/social/view/profile_page.dart:4` — imports `package:social_api_client`
- `lib/social/view/messages_page.dart:3` — imports `package:messaging_api_client`
- `lib/map/view/widgets/weather_advisory_card.dart:4` — imports `package:weather_api_client`

A widget rendering a `SocialPost` or `ZoneFeedMetadata` is reaching two layers down. This is the clearest cross-layer violation in the codebase.

#### 2. Business-logic cubits import the data layer for model/exception types (Important)

These cubits correctly call repositories for data access, but still import `*_api_client` directly to reference the model/exception types the repository returns:

- `lib/auth/auth_cubit.dart:1` (`AuthSession`, `AuthApiException`)
- `lib/social/cubit/feed_cubit.dart:3` (`SocialPost`, `SocialApiException`)
- `lib/social/cubit/create_post_cubit.dart:3` (`SocialPost`, `SocialApiException`)
- `lib/social/cubit/profile_cubit.dart:3`
- `lib/social/cubit/post_detail_cubit.dart:3`
- `lib/messaging/cubit/chat_cubit.dart:4` (`ChatMessage`, `MessagingApiException`)
- `lib/messaging/cubit/threads_cubit.dart:3`
- `lib/messaging/cubit/notification_preferences_cubit.dart:3`
- `lib/map/cubit/map_weather_cubit.dart:4` (`weather_api_client`)
- `lib/weather/weather_alerts_cubit.dart:4` (`WeatherAlertSubscription`, `WeatherApiException`)

**Root cause:** the repositories pass data-layer types through unchanged and do not re-export them. For example `SocialRepository.feed()` returns `List<SocialPost>` where `SocialPost` is defined in `social_api_client`, and `social_repository.dart` exports only `src/social_repository.dart` — not the model. So any consumer must import the data package to name the return type.

Contrast with the repositories that get this right:
- `packages/geocoding_repository/lib/geocoding_repository.dart:5` — `export 'package:geocoding_api_client/...' show GeocodeResult, GeocodingException, GeocodingFailure;` so consumers import only the repository.
- `packages/settings_repository` defines its own domain enum `AppThemeMode`; `SettingsCubit` maps it to Flutter's `ThemeMode` (`lib/settings/settings_cubit.dart:61`). This is the model layer-separation pattern.
- `packages/flight_rules_repository` defines its own domain models (`FlyZone`, `PermissionLevel`, `FlightModality`, `AltitudeRange`, `FlightAssessment`); `MapCubit` depends only on the repository and stays Flutter-free.

The inconsistency is the real issue: four repositories (`social_repository`, `messaging_repository`, `weather_repository`, `auth_repository`) neither define domain models nor re-export their data types, while their peers do.

#### 3. `ZoneSyncService` performs repository composition in the presentation layer (Important)

`lib/zone_sync/zone_sync_service.dart` lives in `lib/` but:
- holds two **data** clients directly (`BackendZonesApiClient`, and imports `zones_api_client` at lines 1 & 3),
- performs repository-layer composition (`FlightRulesRepository.load(feed: backendZonesClient)` at line 14),
- exposes the data-layer type `ZoneFeedMetadata` (line 11).

This is repository-layer wiring/ownership that has leaked into the presentation module. The composition (data client → repository) belongs in `bootstrap.dart` (which already does exactly this for the initial load) or behind the repository.

### Clean files

- `lib/bootstrap.dart` — correct composition root; importing data clients here to assemble repositories is expected and correct.
- `lib/app/app.dart` — provides only repositories/cubits; no data-layer imports.
- `lib/map/cubit/map_cubit.dart` — depends only on `flight_rules_repository` + `settings_repository`; no Flutter import in business logic.
- `lib/settings/settings_cubit.dart` — exemplary domain→Flutter mapping at the boundary.

---

## State Management Assessment

State management is **Bloc/Cubit**, wired via `flutter_bloc` providers. Overall: correct.

- **Immutability:** All inspected states (`MapState`, `AuthState`, `FeedState`, `ChatState`, `WeatherAlertsState`, `CreatePostState`, `SettingsState`) extend `Equatable`, use `final` fields, and expose `copyWith`. No mutable state fields found. ✔
- **Business logic location:** Logic lives in cubits, not widgets (e.g. `MapCubit._reassessed`, `AuthCubit.checkSession`). ✔
- **Data access:** Cubits call repositories, never data sources, for behavior. ✔ (The remaining coupling is type-level — see Layer Separation #2.)
- **Provider/injection & lifecycle:** Repositories provided via `MultiRepositoryProvider` in `app.dart`; the app-scoped `AuthCubit` is created in `_AppState` and correctly `close()`d in `dispose()` (`lib/app/app.dart:67`). `RouterAuthRefresh` is disposed too. ✔
- **Naming:** Descriptive (`MapCubit`, `WeatherAlertsCubit`, `NotificationPreferencesCubit`); no generic `Manager`/`Handler`. ✔
- **Complexity match:** Cubits (not full Blocs) for these flows is appropriate. ✔

Minor nit: `ChatState.copyWith` is defined in a private `extension on ChatState` (`lib/messaging/cubit/chat_cubit.dart:102`) while every other state defines `copyWith` as an instance method. Cosmetic inconsistency only.

---

## Dependency Direction

The package dependency graph is clean and one-directional. Verified from every `pubspec.yaml`:

- **Repositories depend only on data clients**, never on each other and never on `lib/`:
  - `auth_repository → auth_api_client, storage`
  - `social_repository → social_api_client`
  - `weather_repository → weather_api_client`
  - `messaging_repository → messaging_api_client`
  - `flight_rules_repository → zones_api_client`
  - `geocoding_repository → geocoding_api_client, storage`
  - `location_repository → location_client`
  - `settings_repository → storage`
- **Data-to-data composition** (acceptable): `backend_zones_api_client → zones_api_client + storage`.
- **No circular dependencies** detected.
- **Backend** reuses the shared data packages `zones_api_client` and `argentina_bounds` — sensible code reuse of pure-Dart models/logic across app and server.

### Repository layer transitively depends on Flutter (Important)

The README states repository packages "never import Flutter." In code they don't `import 'package:flutter/...'`, but `storage` is a **Flutter** data client (depends on `flutter` + `shared_preferences`, `packages/storage/pubspec.yaml:11`). Therefore `auth_repository`, `geocoding_repository`, and `settings_repository` **transitively** pull Flutter into the repository layer. These repositories can no longer be tested or reused in a pure-Dart (e.g. CLI/server) context. To honor the stated invariant, `storage` would need a platform-agnostic key/value abstraction with the SharedPreferences implementation injected, or the README claim should be softened.

---

## Package Structure

All 18 packages are well-formed:

- Each has a `pubspec.yaml` with a clear name/description and `publish_to: "none"`.
- Each declares `very_good_analysis` and a `test`/`flutter_test` dev dependency.
- Each has a single, clear responsibility; data clients and repositories are cleanly separated into distinct packages.
- UI/business logic is kept out of the data and repository packages (those are pure Dart, except the intentionally-Flutter data clients `storage`, `location_client`, `backend_zones_api_client`).

### Findings

- **Lint version drift (Suggestion):** `argentina_bounds` uses `very_good_analysis: ^7.0.0` while every other package (and the app) uses `^6.0.0`. Align to one major version across the monorepo.

### Backend (`backend/`)

Cleanly layered for a Dart Frog service:
- **Transport:** `routes/**` handle HTTP only and delegate to services via `AppContainer.instance.<service>` (e.g. `routes/v1/posts/index.dart` → `postService.getFeed/createPost`).
- **Business logic:** `lib/services/**` (auth, post, messaging, weather, zone, notification, …).
- **Data:** `lib/db/database.dart`; **DI:** `lib/app_container.dart` singleton wires config → db → services.
- Supporting `config/`, `models/`, `middleware/`, `util/` are appropriately scoped.
- Pure Dart (no Flutter). No layering violations observed in the routes/services sampled.

---

## Verdict

**Needs work** — the architecture is fundamentally sound (clean package graph, no cycles, solid state management, clean backend), but the presentation↔data boundary is breached repeatedly. Fix the boundary by making the four "pass-through" repositories expose domain types (or re-export their data types via `export ... show`, as `geocoding_repository` already does), then remove the direct `*_api_client` imports from `lib/` — especially the UI widgets. Relocate `ZoneSyncService`'s data-client composition behind the repository/bootstrap. These are mechanical, low-risk changes that bring the codebase fully in line with its own stated architecture.

### Issue count
- **Critical:** 1 — UI widgets import the data layer directly (8 files).
- **Important:** 3 — cubits coupled to data-layer types/exceptions; repository layer transitively depends on Flutter via `storage`; `ZoneSyncService` does repository composition in `lib/`.
- **Suggestions:** 2 — unify the repository boundary pattern (domain models vs re-export); align `very_good_analysis` versions. (Plus a cosmetic `ChatState.copyWith` note.)
