# where_to_fly.ar — Dónde Volar 🇦🇷🚁

[![Flutter](https://img.shields.io/badge/Flutter-3.6+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6+-0175C2?logo=dart)](https://dart.dev)

![where_to_fly — Know where you can and can't fly your drone across Argentina](where_to_fly-portfolio-cover.png)

**Know where you can — and can't — fly your drone across Argentina.**

Tap anywhere on the map and the app tells you whether you may fly there for your selected ANAC permission and flight modality — and, if not, how to request the right authorization. Built on the [ANAC regulatory framework](https://www.argentina.gob.ar/anac/nuevo-marco-normativo-para-la-operacion-de-drones) (Resolución ANAC 550/2025 and RAAC 100).

## Features

### Map & flight rules

- **Interactive map** — [flutter_map](https://pub.dev/packages/flutter_map) with **CARTO** basemaps (Voyager light / Dark Matter dark, no API key). Colour-coded restriction zones across Argentina; optional [MapTiler](https://www.maptiler.com/) styles via `--dart-define` (see [Map tiles](#map-tiles)).
- **Tap-to-check** — verdicts *Podés volar* / *Podés volar con tu permiso* / *No podés volar*, with the zones involved.
- **Flight modality** — VLOS, EVLOS, **BVLOS / full FPV**, night, and over-people; each modality maps to a minimum ANAC authorization (e.g. BVLOS blocked for recreational pilots even in open airspace).
- **Permission levels** — Recreativo, piloto registrado ANAC, autorizado/comercial, permiso especial por zona; verdict updates live.
- **Zone categories** — controlled airspace (CTR), prohibited, restricted, national parks, critical infrastructure — fed from the backend (ANAC MADHEL, OpenAIP, bundled baseline).
- **Locate me** — centre on GPS and check the spot immediately.
- **Search** — geocode Argentine places via OpenStreetMap Nominatim (no API key); successful lookups cached for **offline** resolution.
- **Offline rules** — zone cache + local `FlightRulesRepository` verdicts work without a network; map tiles and first-time zone sync need connectivity.
- **Wind overlay** — optional Open-Meteo gust raster (`.om` + `wasm_run`); see [Wind field](#wind-field-open-meteo).
- **Resources** — step-by-step guidance and links to official ANAC / Argentina.gob.ar permission pages.

### Account, social & messaging

- **Auth** — sign up / log in against the Dónde Volar backend; session restored on launch (`/splash` → map or login).
- **Social** — feed, explore, posts (photo/video), profiles, likes and comments.
- **Messaging** — direct threads and in-app chat.

### App experience

- **Bilingual (EN / ES)** — UI via Flutter `gen-l10n`; regulatory text stays in Spanish to match ANAC terminology.
- **Light & dark themes** — Material 3, persisted; map style follows appearance.
- **Layered monorepo** — VGV-style packages under `packages/`, Bloc + GoRouter in `lib/`.

## Architecture

[Very Good Ventures layered architecture][vgv-arch]: one-directional dependencies  
`data` ← `repository` ← `business logic` ← `presentation`. Repository packages do not import Flutter.

```
where_to_fly/
  lib/                          # presentation + business logic
    bootstrap.dart              # wires clients → repositories → App
    app/                        # MaterialApp, GoRouter, shell tabs
    auth/                       # AuthCubit, login, signup, splash
    map/                        # MapCubit, flutter_map UI, wind overlay
    social/                     # feed, explore, posts, profiles
    messaging/                  # threads, chat
    settings/  resources/  l10n/
  packages/
    auth_api_client/  auth_repository/
    backend_zones_api_client/  zones_api_client/
    flight_rules_repository/
    geocoding_api_client/  geocoding_repository/
    location_client/  location_repository/
    messaging_api_client/  messaging_repository/
    social_api_client/  social_repository/
    settings_repository/  storage/
    weather_api_client/  weather_repository/
    argentina_bounds/
  backend/                      # Dart API — zones ingest, auth, social, messaging
```

`MapCubit` composes `FlightRulesRepository` for geofence + verdict logic; zone polygons come from `backend_zones_api_client` with local cache and bundled fallback.

[vgv-arch]: https://engineering.verygood.ventures/development/architecture/architecture/

## Running

> Errors like *"Couldn't resolve `flutter_localizations`"* or missing `app_localizations.dart` → run `flutter pub get` (regenerates `lib/l10n/gen/`).

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```

Point the app at your backend (see `lib/config/api_config.dart` or `--dart-define` for base URL). For iOS: `cd ios && pod install` (minimum iOS 15).

### Map tiles

Default: **CARTO** raster tiles via flutter_map (attribution on-map). Custom MapTiler URLs:

```bash
flutter run \
  --dart-define=MAP_STYLE_URL_LIGHT=https://api.maptiler.com/maps/streets-v2/style.json?key=YOUR_KEY \
  --dart-define=MAP_STYLE_URL_DARK=https://api.maptiler.com/maps/dataviz-dark/style.json?key=YOUR_KEY
```

### Wind field (Open-Meteo)

Toggle with the **wind** FAB. Decodes `.om` tiles via WASM in `assets/om/` (GPL-2.0-only). Needs network to `map-tiles.open-meteo.com` unless you run the local tile server in `tooling/om_tile_server/`.

```bash
flutter run --dart-define=WIND_MAP_ENABLED=false   # hide FAB
```

### Platform permissions

Configured in `AndroidManifest.xml` (`INTERNET`, location) and `Info.plist` (`NSLocationWhenInUseUsageDescription`).

### Branding assets

Launcher icon and native splash are generated from `assets/icon/`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Zone data

Published by the **Dónde Volar backend** (`GET /v1/zones`), merging:

1. **Bundled baseline** — parks, prohibited/restricted government sites, critical infrastructure.
2. **ANAC MADHEL** — `https://datos.anac.gob.ar/madhel/api/v2/airports/`.
3. **OpenAIP** — controlled/restricted airspace when `OPENAIP_API_KEY` is set on the backend.

The app caches zones locally; unreachable backend + empty cache falls back to a bundled emergency snapshot.

```bash
# Refresh feed (authenticated)
curl -X POST http://localhost:8080/v1/zones/ingest \
  -H "Authorization: Bearer <access-token>"

# Optional static mirror
dart run packages/zones_api_client/tool/export_geojson.dart > feed/zones.geojson
```

Zones are modelled as circles (MADHEL centres + category default radii). **Always confirm current ANAC NOTAMs/AIP before flying.**

## Regulatory sources

- [ANAC — Nuevo marco normativo para drones](https://www.argentina.gob.ar/anac/nuevo-marco-normativo-para-la-operacion-de-drones)
- [ANAC — RPA / RPAS](https://www.argentina.gob.ar/anac/rpa-rpas)
- Resolución ANAC 550/2025 / RAAC 100 — Categorías Abierta, Específica, Certificada; 122 m ceiling; &lt; 250 g deregulation rules.

## License

See repository license files. Open-Meteo wind WASM assets under `assets/om/` are GPL-2.0-only.
