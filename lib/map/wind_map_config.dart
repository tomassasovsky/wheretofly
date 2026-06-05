import 'package:flutter/foundation.dart';

/// Open-Meteo wind field configuration.
abstract final class WindMapConfig {
  /// Overrides [enabled] in widget tests (avoids wind tile HTTP during map
  /// tests).
  @visibleForTesting
  static bool? enabledOverride;

  /// Set `--dart-define=WIND_MAP_ENABLED=false` to hide the wind layer toggle.
  static bool get enabled =>
      enabledOverride ??
      const bool.fromEnvironment(
        'WIND_MAP_ENABLED',
        defaultValue: true,
      );

  static const model = 'dwd_icon';

  /// Scalar gust field (≥ 0, uses the `wind` colorscale in weather-map-layer).
  static const variable = 'wind_gusts_10m';

  static const timeStep = 'current_time_1H';

  /// Max slippy zoom for wind gust tiles and vector samples.
  static const windMaxZoom = 12;

  /// Gust overlay strength (0–1). Lower values keep the basemap more visible.
  static const windLayerOpacity = 0.55;

  /// Remote gust PNG base URL (no trailing slash).
  ///
  /// Set at startup when WASM decode is unavailable (typical on iOS).
  /// Override with `--dart-define=WIND_TILE_BASE_URL=...` (e.g. dev
  /// `http://127.0.0.1:8765` from `tooling/om_tile_server`).
  static String? _remoteBaseUrl;

  static set windTileBaseUrl(String baseUrl) => _remoteBaseUrl = baseUrl;

  static String get windTileBaseUrl {
    const env = String.fromEnvironment('WIND_TILE_BASE_URL');
    if (env.isNotEmpty) return env;
    return _remoteBaseUrl ?? '';
  }
}
