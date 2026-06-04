import 'package:flutter/foundation.dart';

/// Open-Meteo wind field configuration.
abstract final class WindMapConfig {
  /// Set `--dart-define=WIND_MAP_ENABLED=false` to hide the wind layer toggle.
  static const enabled = bool.fromEnvironment(
    'WIND_MAP_ENABLED',
    defaultValue: true,
  );

  /// QA only: open the map tab directly in wind mode (simulator screenshots).
  static const autoOpen = bool.fromEnvironment('WIND_MAP_AUTO_OPEN');

  /// Direction arrows over the gust layer (off until performance is ready).
  static const arrowsEnabled = false;

  static const model = 'dwd_icon';

  /// Scalar gust field (≥ 0, uses the `wind` colorscale in weather-map-layer).
  static const variable = 'wind_gusts_10m';

  /// 10 m wind components for direction arrows (same `.om` file as [variable]).
  static const windUVariable = 'wind_u_component_10m';
  static const windVVariable = 'wind_v_component_10m';

  static const timeStep = 'current_time_1H';

  /// Max slippy zoom for wind gust tiles and vector samples.
  static const windMaxZoom = 12;

  /// Gust overlay strength (0–1). Lower values keep the basemap more visible.
  static const windLayerOpacity = 0.55;

  /// Open-Meteo minimal style (official wind example).
  /// Slower on first WebView open.
  static const openMeteoStyleUrl =
      'https://map-assets.open-meteo.com/styles/minimal-planet-maps.json';

  /// Basemap shell must load before the map is interactive (not wind tiles).
  static const shellTimeout = Duration(seconds: 45);

  /// Open-Meteo om:// tiles can take longer on mobile WebViews.
  static const windTilesCheckTimeout = Duration(seconds: 45);

  /// iOS/Wasmi cannot run the SIMD OM decoder. Point at a dev tile server
  /// (`dart run tooling/om_tile_server/bin/server.dart`) — Mac or Linux.
  ///
  /// Serves `/<z>/<x>/<y>.png` (gust) and `/<z>/<x>/<y>.json` (u/v samples).
  /// Override with `--dart-define=WIND_TILE_BASE_URL=http://127.0.0.1:8765`
  /// (simulator) or `http://<host-lan-ip>:8765` (physical device).
  ///
  /// In debug on iOS, defaults to `http://127.0.0.1:8765` when unset so the
  /// simulator works if the tile server is running (no dart-define required).
  static String get windTileBaseUrl {
    const env = String.fromEnvironment('WIND_TILE_BASE_URL');
    if (env.isNotEmpty) return env;
    if (kDebugMode && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://127.0.0.1:8765';
    }
    return '';
  }
}
