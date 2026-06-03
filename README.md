# Dónde Volar 🇦🇷🚁

A Flutter app to check **where you can and can't fly a drone in Argentina**,
based on the ANAC regulatory framework (Resolución ANAC 550/2025 and RAAC 100)
and the permission level you hold.

Tap anywhere on the map and the app tells you whether you may fly there given
your selected permission — and, if not, how to request the right authorization.

## Features

- **Interactive map** ([MapLibre](https://maplibre.org/) via the
  [`maplibre`](https://pub.dev/packages/maplibre) package) showing
  colour-coded restriction zones across Argentina. Uses free demo tiles by
  default; optional MapTiler styles via dart-define (see *Map tiles* below).
- **Tap-to-check**: tap any point to get a verdict — *Podés volar* /
  *Podés volar con tu permiso* / *No podés volar* — with the specific zones
  involved.
- **Configurable flight modality**: VLOS, EVLOS, **BVLOS / full FPV**, night,
  and over-people. Each modality has a minimum ANAC authorization, so the
  verdict accounts for *how* you fly, not just *where* — e.g. BVLOS/FPV is
  blocked for a recreational pilot even in otherwise-open airspace.
- **Clean Google-Maps-style UI**: full-screen map, a floating pill search bar,
  right-side circular buttons (locate / layers), and a bottom card that opens a
  configuration sheet for permission + modality. No app-bar clutter.
- **Permission-aware**: switch between the four permission levels and the
  verdict updates live:
  - **Recreativo / sin licencia** — Categoría Abierta (sub-250 g essentially
    deregulated; VLOS, day, ≤122 m).
  - **Piloto registrado ANAC** — registered operator.
  - **Autorizado / comercial** — Categoría Específica (operational
    authorization: BVLOS, night, urban).
  - **Permiso especial por zona** — case-by-case clearance (ATC, parks, etc.).
- **Zone categories**: controlled airspace (CTR), prohibited, restricted,
  national parks, and critical infrastructure — **759 zones** including the
  full ANAC MADHEL aerodrome/heliport catalog (712 sites), all 35 national
  parks, government/military sites, and critical infrastructure.
- **Locate me**: a button uses `geolocator` to centre the map on your current
  position and immediately check whether you can fly there.
- **Search**: a search box geocodes any Argentine city or address (OpenStreetMap
  Nominatim, no API key) and flies the map there, then checks it. Successful
  lookups are cached so previously searched places still resolve **offline**.
- **Works offline (rules & data)**: the zone dataset is bundled in the app and
  the verdict logic runs locally, so checking "can I fly here?" works without a
  connection. Cached search results also resolve offline. Only the Google Maps
  base tiles require a connection (the Google Maps SDK does not allow custom
  offline tile caching).
- **Remembers your choices**: the selected permission level, language and
  appearance are persisted (via the `settings_repository` / `storage`
  packages). A settings menu (iOS-style action sheets) lets you switch
  language and appearance.
- **Light & dark themes + iOS look**: Material 3 light/dark themes (system /
  light / dark, persisted), Cupertino page transitions, flat app bars,
  CupertinoIcons, and a base map that matches the app appearance (dark mode
  uses the Google Maps night style on mobile; web uses `MapColorScheme`).
- **Bilingual (English / Spanish)**: UI chrome is localized via Flutter
  `gen-l10n` (ARB files), following the device locale. Regulatory/domain text
  (zone names, legal rationale) is kept in Spanish on purpose, as it mirrors
  the official ANAC terminology.
- **Resources screen** with step-by-step guidance and links to official ANAC /
  Argentina.gob.ar pages to request each permission.

## Architecture

Follows the [Very Good Ventures layered architecture][vgv-arch]: four layers
with strict, one-directional dependencies
(`data` ← `repository` ← `business logic` ← `presentation`). Per VGV, the
**data and repository layers live as standalone packages under `packages/`**,
while the **presentation + business logic live in `lib/`**. Each layer only
talks to the one directly beneath it, and repository packages never import
Flutter.

```
where_to_fly/
  lib/                                  # PRESENTATION + BUSINESS LOGIC
    bootstrap.dart                      # composes data clients -> repositories
    app/app.dart                        # repository providers + MaterialApp
    map/
      cubit/                            # MapCubit + MapState (business logic)
      view/                             # MapPage/MapView + widgets (presentation)
    settings/settings_cubit.dart        # business logic (maps domain -> ThemeMode)
    resources/                          # presentation
    theme/  l10n/                       # theme + generated localizations
  packages/
    # ----- DATA LAYER (raw sources, no domain logic) -----
    zones_api_client/                   # bundled ANAC zone dataset -> ZoneData
    geocoding_api_client/               # Nominatim HTTP client -> GeocodeResult
    location_client/                    # geolocator wrapper
    storage/                            # SharedPreferences wrapper
    # ----- REPOSITORY LAYER (domain rules, no Flutter) -----
    flight_rules_repository/            # ZoneData -> FlyZone + assess() verdicts
    geocoding_repository/               # geocoding + offline cache policy
    location_repository/                # device location as a domain value
    settings_repository/                # permission / language / theme persistence
```

Key points that make this *layered* (not clean) architecture: there are no
abstract repository interfaces / use-cases; data clients are concrete; domain
models live in the repository packages; and the repositories depend only on
data clients (never on each other or on Flutter). `MapCubit` (business logic)
composes `FlightRulesRepository`, whose geofence + verdict rules keep the UI
thin and each layer testable in isolation.

[vgv-arch]: https://engineering.verygood.ventures/development/architecture/architecture/

## Running

> If you see errors like *"Couldn't resolve the package 'flutter_localizations'"*
> or undefined `GlobalMaterialLocalizations`, you just need to run
> `flutter pub get` — the dependency is declared but the package config must be
> refreshed (this also regenerates `lib/l10n/gen/`).

```bash
flutter pub get        # resolves deps + runs gen-l10n -> lib/l10n/gen/
flutter gen-l10n       # (only if needed) regenerate localizations manually
flutter run            # launches on a connected device / emulator
flutter test           # runs the unit + cubit tests
flutter analyze        # lints against very_good_analysis
```

The localization classes under `lib/l10n/gen/` are generated by `flutter
gen-l10n` (triggered automatically by `flutter pub get` because
`generate: true` is set in `pubspec.yaml`). They are intentionally not checked
in; if your IDE shows the `app_localizations.dart` import as missing, run
`flutter pub get` once.

### Map tiles

By default the app loads **CARTO** raster basemaps via [flutter_map](https://pub.dev/packages/flutter_map)
(no API key): Voyager (light) and Dark Matter (dark), with attribution on the map.
Zone circles use **meter radius** and scale while you zoom.

For custom styles (e.g. [MapTiler](https://www.maptiler.com/)), pass URLs at
build time (never commit API keys):

```bash
flutter run \
  --dart-define=MAP_STYLE_URL_LIGHT=https://api.maptiler.com/maps/streets-v2/style.json?key=YOUR_KEY \
  --dart-define=MAP_STYLE_URL_DARK=https://api.maptiler.com/maps/dataviz-dark/style.json?key=YOUR_KEY
```

Attribution for the active tile provider is shown on the map via
`SourceAttribution`.

### Wind field (Open-Meteo)

The map is a single **flutter_map** view (zones, tap-to-check, search). Use
the **wind** FAB (air icon) to show or hide an Open-Meteo **gust overlay**
(WebView raster on top, same camera). **Does not use your backend** — it needs
internet to `map-tiles.open-meteo.com`. MapLibre GL JS + weather-map-layer are
bundled in `assets/wind_map/` (GPL-2.0).

- Hide the toggle: `flutter run --dart-define=WIND_MAP_ENABLED=false`
- Refresh vendored JS: `./scripts/vendor_wind_map_assets.sh`
- Capture simulator screenshots: `flutter test integration_test/wind_map_screenshot_test.dart -d <device_id>`

### Platform permissions (already configured)

- **Android** (`AndroidManifest.xml`): `INTERNET`, `ACCESS_FINE_LOCATION` and
  `ACCESS_COARSE_LOCATION`.
- **iOS** (`Info.plist`): `NSLocationWhenInUseUsageDescription` for the
  locate-me feature.

### iOS notes

After `flutter pub get`, run `cd ios && pod install`. MapLibre requires iOS 15+
(`platform :ios, '15.0'` in `ios/Podfile`).

## Zone data

All map zone data is served by the **Dónde Volar backend** (`GET /v1/zones`).
The backend merges and publishes a single GeoJSON feed from:

1. **Bundled baseline** — national parks, prohibited government/defence sites,
   restricted sites, and critical infrastructure (nuclear plants, major dams).
2. **ANAC MADHEL** — live aerodrome and heliport catalog from
   `https://datos.anac.gob.ar/madhel/api/v2/airports/`.
3. **OpenAIP** — live controlled/restricted airspace for Argentina (when
   `OPENAIP_API_KEY` is set on the backend).

The Flutter app loads zones from the backend at startup and caches them locally
for offline use. If the backend is unreachable and no cache exists yet, the app
falls back to a bundled emergency snapshot.

Refresh the published feed manually:

```bash
curl -X POST http://localhost:8080/v1/zones/ingest \
  -H "Authorization: Bearer <access-token>"
```

Or schedule it via `POST /v1/cron/zone_ingest` with header
`x-cron-secret: <JWT_SECRET>`.

Regenerate the static snapshot checked into the repo (optional hosting mirror):

```bash
dart run packages/zones_api_client/tool/export_geojson.dart > feed/zones.geojson
```

Zones are modelled as circles; centres come from MADHEL coordinates and radii
are category defaults (controlled intl 12 km, controlled 9 km, uncontrolled
5 km, heliport 2–3 km). Always confirm against current ANAC NOTAMs/AIP before
each flight.

## Regulatory sources

- ANAC — Nuevo marco normativo para la operación de drones:
  https://www.argentina.gob.ar/anac/nuevo-marco-normativo-para-la-operacion-de-drones
- ANAC — RPA / RPAS: https://www.argentina.gob.ar/anac/rpa-rpas
- Resolución ANAC 550/2025 / RAAC 100 (Categorías Abierta, Específica,
  Certificada; techo de 122 m; desregulación de equipos < 250 g).
