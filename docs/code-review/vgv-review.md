# VGV Code Review — `where_to_fly`

_Reviewed against Very Good Ventures engineering standards. Scope: Flutter app
(`lib/`), layered packages (`packages/*/lib/`), and the Dart Frog backend
(`backend/lib/`, `backend/routes/`). Generated code, `tooling/`, vendored
assets, and `docs/` were excluded._

## Summary

This is a **high-quality, convention-driven codebase** that already follows the
vast majority of VGV's engineering standards. The layered architecture
(data client → repository → presentation) is clean and consistent across every
feature, state is immutable and `Equatable`, cubits are small and focused, and
`flutter analyze` runs clean under the strict
`very_good_analysis` ruleset (with `strict-casts` and `strict-raw-types`
enabled). Resource disposal, debounce cancellation, and request-race guarding
are handled correctly where they matter.

The codebase is **not yet ready to merge as a production release** for two
reasons: (1) a placeholder media URL is hardwired into the live post-creation
flow, and (2) **8 of 13 cubits and most of the backend have no tests** — at VGV,
untested state management is unfinished work. The remaining findings are
security hardening (token-at-rest, default secrets) and minor convention drift.

**Verdict: Needs work** (mostly test coverage + the placeholder fix).

---

## 🔴 Critical — Must Fix Before Merge

- **`lib/social/cubit/create_post_cubit.dart:37-53`** — The post-creation flow
  hardcodes a random stock image as the post's media:
  ```dart
  'storageKey': 'https://picsum.photos/seed/$seed/1080/1920',
  ```
  - Why: This is the production "create post" path. Whatever media the user
    actually selected is discarded and replaced with a placeholder from
    `picsum.photos`. This ships a broken core feature and adds an undeclared
    runtime dependency on a third-party image host.
  - Fix: Wire the real upload pipeline (the backend already exposes MinIO/S3
    config). If media upload is genuinely out of scope for this release, gate the
    create-post entry point behind a feature flag rather than shipping a stub in
    the happy path.

- **Missing unit tests for 8 of 13 cubits.** No test files exist for:
  `AuthCubit`, `ChatCubit`, `NotificationPreferencesCubit`, `ThreadsCubit`,
  `CreatePostCubit`, `PostDetailCubit`, `ProfileCubit`, `WeatherAlertsCubit`.
  (Tested: `MapCubit`, `MapSearchCubit`, `MapWeatherCubit`, `FeedCubit`,
  `SettingsCubit`.)
  - Why: State management is the heart of the app's behavior. At VGV every
    cubit must have a `bloc_test`-based test covering success, failure, and edge
    transitions. `AuthCubit` in particular drives the entire session/redirect
    lifecycle (`checkSession`, refresh-on-expiry, `validateStoredSession`
    fallback to logout) and is completely untested.
  - Fix: Add `blocTest` coverage for each cubit. Prioritize `AuthCubit` (token
    expiry + refresh-failure → logout branches), `CreatePostCubit`,
    `WeatherAlertsCubit`, and the social cubits. Mock repositories with
    `mocktail` (already a dev dependency) and assert emitted state sequences.

---

## 🟡 Important — Should Fix

- **`packages/storage/lib/src/storage.dart` + `packages/auth_repository/lib/src/auth_repository.dart:90-92`**
  — Auth sessions, including the **refresh token**, are persisted as plain JSON
  in `SharedPreferences`.
  - Why: `SharedPreferences` is unencrypted (plist on iOS, XML on Android). A
    long-lived refresh token at rest in clear text is a security risk and a
    common VGV static-security finding.
  - Fix: Store the session via `flutter_secure_storage` (Keychain / Keystore /
    EncryptedSharedPreferences), or add an encrypted `SecureStorage` data client
    used specifically by `AuthRepository`. Keep non-sensitive settings on the
    existing `Storage`.

- **`backend/lib/config/app_config.dart:25-45`** — Insecure defaults with no
  production fail-fast: `jwtSecret` defaults to `'dev-secret-change-me'`, and
  MinIO defaults to `minioadmin` / `minioadmin`.
  - Why: If the server boots without the env vars set, it silently signs tokens
    with a publicly-known secret — a full auth bypass. Dev-friendly defaults are
    fine, but they must not be reachable in production.
  - Fix: Detect a production/release environment and throw on startup when
    `JWT_SECRET` (and other secrets) are unset or equal to the known dev value.

- **Backend test coverage is thin.** Only 4 test files
  (`index`, `geocoding_service`, `jwt_service`, `weather_service`) exist for
  ~30 routes and ~15 services. `AuthService`, `PostService`,
  `MessagingService`, `NotificationService`, `ZoneService`/`ZoneIngestService`,
  `PasswordHasher`, and the middleware are untested.
  - Why: The backend owns authentication, authorization, and data integrity.
    Untested auth/route handlers are high-risk.
  - Fix: Add route + service tests, prioritizing the auth routes
    (`signup`/`login`/`refresh`/`session`) and the auth middleware.

- **`lib/weather/weather_alerts_cubit.dart:72-104`** — Error handling is
  inconsistent and partly silent. `remove(id)` calls
  `deleteAlertSubscription` with **no try/catch** and optimistically drops the
  item from state regardless of outcome; `save(...)` swallows every error and
  only returns a `bool`, so the UI cannot surface a reason.
  - Why: A failed network delete leaves the UI showing success while the
    backend still has the subscription (state divergence). Bare `async` without
    error handling is an anti-pattern flagged by VGV.
  - Fix: Wrap `remove` in try/catch, emit an error state (or re-add on
    failure). Have `save` emit an error state instead of (or in addition to)
    returning a bool.

- **Inconsistent `copyWith` placement across states.** Most states define
  `copyWith` inside the state class (`AuthState`, `WeatherAlertsState`,
  `ProfileState`, `PostDetailState`), but `ChatState`
  (`lib/messaging/cubit/chat_cubit.dart:102`) and `NotificationPreferencesState`
  (`lib/messaging/cubit/notification_preferences_cubit.dart:94`) define it via a
  private `extension on`.
  - Why: Convention drift makes the codebase harder to read and pattern-match
    against. VGV favors one consistent shape.
  - Fix: Pick one convention (in-class `copyWith` is the more common VGV
    pattern here) and apply it uniformly.

---

## 🔵 Suggestions — Nice to Have

- **`lib/app/app.dart:89-153`** — Four levels of nested `BlocProvider` plus a
  nested `MultiBlocListener`/`BlocBuilder`. Functionally correct, but a
  `MultiBlocProvider` would flatten the pyramid and improve readability.

- **`backend/lib/middleware/auth.dart:40-44`** — `Access-Control-Allow-Origin:
  '*'`. Acceptable for token-based (non-cookie) auth, but consider restricting
  to known origins for production hardening.

- **Logging is split between `dart:developer` `log` (bootstrap/observer) and
  `debugPrint` (`reel_video_background.dart`, `wind_direction_overlay.dart`,
  `flutter_map_layer.dart`).** Consider a single thin logging utility for
  consistency. (None of these run in release paths, so this is minor.)

- **`lib/social/cubit/profile_cubit.dart:81-99`** — After a successful
  `follow()`, the emitted state only clears `followPending`; it does not update
  the profile's follower count / `isFollowing` flag. Consider reflecting the new
  follow state so the UI is consistent without a reload.

---

## Simplicity Assessment

- **Lines that could be removed:** Minimal. The placeholder media block in
  `create_post_cubit.dart` should be replaced (not just removed). No dead code,
  commented-out blocks, or speculative abstractions were found.
- **Unnecessary abstractions:** None. Repositories and api clients each earn
  their keep (one implementation each, clear layer boundary). `Storage` is a
  deliberately thin, single-responsibility wrapper.
- **YAGNI violations:** None of note.
- **Complexity verdict:** **Already minimal.** Cubits are small and focused;
  the largest files are legitimately complex domains (wind/OM decoding, zone
  detail UI) rather than accidental complexity.

## Testing Assessment

- **New/feature code with tests:** 🔴 Missing for 8 of 13 cubits and most of the
  backend (see Critical/Important). Good coverage exists for the map/wind domain,
  the social `FeedCubit`, settings, routing/navigation, and the pure-Dart
  packages (`flight_rules_repository`, `zones_api_client`, `argentina_bounds`).
- **Test quality (existing):** Generally meaningful — `bloc_test`, `mocktail`,
  and state-sequence assertions are used correctly where tests exist. No obvious
  tautologies (`expect(true, isTrue)`) were found in the reviewed tests.
- **State management test coverage:** **Partial** — strong on map/feed/settings,
  absent on auth, social detail, messaging, and weather alerts.
- **UI component test coverage:** **Partial** — pages like `SettingsPage`,
  `ResourcesPage`, `MapView`, and `ZoneDetailCard` have widget tests; most
  social/messaging pages do not.

## Notable Strengths (keep doing this)

- Textbook layered architecture: presentation depends only on repositories;
  api clients are sealed behind repositories; no cross-layer leaks found.
- Immutable `Equatable` state everywhere; explicit `clearX` flags in `copyWith`
  to disambiguate "set null" from "leave unchanged".
- `MapSearchCubit` correctly debounces, guards against out-of-order responses
  with a request-id token, and cancels its timer in `close()`.
- Graceful offline degradation in `FeedCubit` (cached posts + `isStale` flag).
- Clean analyzer run under strict casts/raw-types with documented, justified
  inline lint ignores (only two, both in `lib/map/...`).
