# Test Quality Review — `where_to_fly`

_Full-project test coverage and quality audit. Scope: `test/`, `packages/*/test/`,
`backend/test/` against source in `lib/`, `packages/*/lib/`, `backend/lib/`.
Excludes generated files (`**/*.g.dart`, `lib/l10n/gen/**`), `tooling/**`, `docs/**`._

## Coverage Summary

- **Test run**: Not executed in this review (static audit). Existing
  `coverage/lcov.info` is **stale** — it contains records for only
  `lib/map/cubit/map_cubit.dart` and `lib/map/cubit/map_state.dart`, i.e. a
  single-file run. There is no meaningful project-wide coverage artifact and no
  evidence of a coverage threshold being enforced.
- **Test files found**: 49 total
  - App (`test/`): 33
  - Packages (`packages/*/test/`): 12 (across 5 of 18 packages)
  - Backend (`backend/test/`): 4
- **Overall**: The existing tests are generally **high quality** (good use of
  `bloc_test`, `mocktail`, `isA().having()` matchers, seeded states, `setUp`).
  The problem is **breadth**: large portions of the state layer, the data layer
  (API clients/repositories), the UI layer, and the backend have **no tests at
  all**.

### Quality of what exists (positive baseline)

The strongest tests in the repo are good models to copy:

- `test/map_cubit_test.dart` — seeded states, multi-step `act`, behavioral
  assertions on verdict/modality.
- `test/map_search_cubit_test.dart` — covers success, edge (outside Argentina),
  and async `locateMe` loading→loaded transitions with mocked repositories.
- `test/feed_cubit_test.dart` — success and `SocialApiException` error paths with
  proper `mocktail` stubbing.
- `packages/zones_api_client/test/madhel_zones_api_client_test.dart` — HTTP
  client faked via `http.BaseClient`, parse + empty-response failure covered.
- `test/zone_detail_card_test.dart` — widget test with real `AppLocalizations`
  delegates and meaningful text assertions across two distinct rendered states.

---

## Critical Findings

### C1. State layer (cubits) is largely untested

14 `Cubit`/`Bloc` classes exist. Only **5** have dedicated test files. The
following cubits contain real branching logic (loading/loaded/error paths,
optimistic updates) and have **no dedicated test**:

| Cubit | File | Untested logic |
| --- | --- | --- |
| `ChatCubit` | `lib/messaging/cubit/chat_cubit.dart` | `load` (session + messages), `send` (trim guard, optimistic append, error keeps `loaded`) |
| `ThreadsCubit` | `lib/messaging/cubit/threads_cubit.dart` | thread list load/error |
| `NotificationPreferencesCubit` | `lib/messaging/cubit/notification_preferences_cubit.dart` | preference load/update |
| `ProfileCubit` | `lib/social/cubit/profile_cubit.dart` | `load` (profile+posts), `follow` (pending guard, error) |
| `PostDetailCubit` | `lib/social/cubit/post_detail_cubit.dart` | detail load, comments, error |
| `CreatePostCubit` | `lib/social/cubit/create_post_cubit.dart` | submit/validation/error |
| `WeatherAlertsCubit` | `lib/weather/weather_alerts_cubit.dart` | `load`/`save` (returns bool on failure)/`remove`/`reset` |
| `AuthCubit` | `lib/auth/auth_cubit.dart` | **partial** — login/signup happy paths exercised indirectly by `auth_navigation_test`, but `checkSession` (token-expiry refresh, `validateStoredSession` failure → logout), `AuthApiException` vs generic error branches, and `logout` are **untested** |

These are the core of the app's behavior. Each should get a `blocTest` suite
covering happy path, typed-exception path, and generic-catch path, mirroring
`feed_cubit_test.dart`.

### C2. Data layer — API clients with real HTTP/parse/error logic are untested

API clients contain the project's most failure-prone code (HTTP, JSON decode,
status-code → exception mapping) and have **no tests**:

- `packages/social_api_client/lib/src/social_api_client.dart` — `_decode`
  handles `FormatException`, `statusCode >= 400` error extraction, non-`Map`
  responses, and a 401 "Not authenticated" guard. None covered.
- `packages/weather_api_client` — fetch + alert subscription CRUD, untested.
- `packages/auth_api_client` — login/signup/refresh request building + parsing,
  untested (security-relevant).
- `packages/messaging_api_client` — untested.
- `packages/geocoding_api_client` — untested.

The pattern already exists in `madhel_zones_api_client_test.dart` (fake
`http.BaseClient`); replicate it for each client covering success, non-200
errors, malformed body, and the unauthenticated guard.

### C3. Backend — most services and nearly all routes are untested

`backend/lib/services/` has 11 services; only 3 are tested
(`geocoding_service`, `weather_service`, `jwt_service`). Untested, including
security-critical ones:

- `auth_service.dart` (login/signup/session) — **untested**
- `password_hasher.dart` (credential hashing/verification) — **untested**
- `zone_service.dart`, `zone_ingest_service.dart`, `notification_service.dart`,
  `weather_alert_service.dart`, `post_service.dart`, `messaging_service.dart` — untested

Routes: ~30 route files under `backend/routes/`; only `index`/`health` is
tested. Auth (`login`, `signup`, `refresh`, `password_reset`, `verify_email`),
`posts`, `users`, `messages`, `notifications`, `reports`, and cron endpoints
have no route tests. Auth and password handling being untested is the highest
risk here.

---

## Important Findings

### I1. Repository layer coverage is thin / indirect

- `messaging_repository`, `social_repository`, `weather_repository`,
  `location_repository`, `storage`, `settings_repository` have **no test files
  in their own package**.
- `social_repository`/`weather_repository` are thin pass-throughs (lower risk),
  but `settings_repository` (persistence + theme/locale parsing) and `storage`
  (the foundational wrapper everything depends on) carry real logic and are only
  exercised *indirectly* via `settings_cubit_test.dart`. They should have direct
  unit tests.

### I2. Misplaced package test (VGV layering violation)

`test/geocoding_repository_test.dart` tests `GeocodingRepository` (caching on
network failure) but lives in the **app's** `test/` folder. Per VGV monorepo
conventions, package tests belong in `packages/geocoding_repository/test/`.
`packages/geocoding_repository/` currently has no `test/` directory. Move the
file so the package owns its own coverage.

### I3. UI layer coverage is sparse

39 files under `lib/**/view/`; only a handful have widget tests
(`zone_detail_card`, `settings_page`, `resources_page`, `map_view`, plus
navigation-focused tests touching `login_page`/`signup_page`). Untested widgets
with rendering/state logic include: `post_card`, `reel_video_background`,
`feed_page`, `profile_page`, `create_post_page`, `post_detail_page`,
`chat_page`, `messages_page`, `explore_page`, `me_tab_page`, `config_sheet`,
`map_legend`, `wind_speed_legend`, `weather_advisory_card`, `map_zoom_controls`,
`search_results_overlay`, `map_fab_column`, `zone_stale_banner`. Each should
have at least a smoke + key-state widget test (using `AppLocalizations`
delegates as in `zone_detail_card_test.dart`).

### I4. No coverage enforcement

`coverage/lcov.info` is stale (single file). There is no CI/threshold gate
visible to keep coverage honest. Without enforcement, the gaps above will
silently grow. Recommend `flutter test --coverage` (and `dart test --coverage`
for backend/packages) wired into CI with a minimum threshold.

---

## Suggestions

### S1. Weak `isNotNull`-only assertions

A few tests assert only existence rather than behavior/value:

- `test/om_wasm_load_test.dart:12,18` — `expect(module, isNotNull)` as the sole
  assertion.
- `test/open_meteo_wind_tile_test.dart:22` — `expect(byteData, isNotNull)`.
- `packages/zones_api_client/test/madhel_zone_mapper_test.dart:20,39,…` —
  `expect(zone, isNotNull)` (though some are followed by stronger checks).

Where `isNotNull` is the only assertion, add value/shape assertions (e.g. decode
a known byte, assert a mapped field) so the test catches regressions, not just
crashes. (In `map_cubit_test.dart` the `isNotNull` checks are paired with
verdict assertions, which is fine.)

### S2. Add model (de)serialization tests for API client models

`social_api_client`, `weather_api_client`, `messaging_api_client`, and
`auth_api_client` ship hand-written `fromJson` models (`SocialPost`,
`SocialProfile`, `SocialComment`, `WeatherSnapshot`, `WeatherAlertSubscription`,
`ChatMessage`, `AuthSession`, etc.). Add round-trip/`fromJson` tests covering
missing/optional fields and `whereType` filtering, since parsing bugs surface
only at runtime today.

### S3. Track and document the test command

No `CLAUDE.md`/`AGENTS.md` documents how tests are run per workspace (root
Flutter app vs. Dart packages vs. Dart Frog backend each have separate
contexts). A short contributor note + a script that runs all three would reduce
the chance of whole sub-projects being skipped.

---

## Recommendations (priority order)

1. **Add `blocTest` suites for the 7 fully-untested cubits + AuthCubit's
   session/error paths** (C1) — highest behavioral value, pattern already
   established in the repo.
2. **Unit-test the API clients** (C2) using the `http.BaseClient` fake pattern;
   prioritize `auth_api_client` and `social_api_client`.
3. **Test backend `auth_service` and `password_hasher`, then the auth routes**
   (C3) — security-critical.
4. **Move `geocoding_repository_test.dart` into its package** and add direct
   tests for `storage` and `settings_repository` (I1, I2).
5. **Add smoke/state widget tests for untested pages and widgets** (I3).
6. **Wire `--coverage` with a threshold into CI** (I4).

## Verdict

**Needs work.** The tests that exist are well-written and idiomatic (VGV
conventions, `bloc_test`, `mocktail`, behavioral matchers), so the bar is set
correctly — but coverage breadth is the problem. Roughly half the state layer,
the majority of the data layer (API clients/repositories), most of the UI, and
most of the backend (including auth and password handling) are untested. Address
the 3 critical gaps (untested cubits, untested API clients, untested backend
auth/services) before treating the suite as merge-ready.
