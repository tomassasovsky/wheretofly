/// Open-Meteo wind field WebView configuration.
abstract final class WindMapConfig {
  /// Set `--dart-define=WIND_MAP_ENABLED=false` to hide the wind layer toggle.
  static const enabled = bool.fromEnvironment(
    'WIND_MAP_ENABLED',
    defaultValue: true,
  );

  /// Use flutter_map TileLayer instead of the WebView gust overlay (WIP).
  static const nativeLayer = bool.fromEnvironment('WIND_MAP_NATIVE');

  /// QA only: open the map tab directly in wind mode (simulator screenshots).
  static const autoOpen = bool.fromEnvironment('WIND_MAP_AUTO_OPEN');

  static const model = 'dwd_icon';

  /// Scalar gust field (≥ 0, uses the `wind` colorscale in weather-map-layer).
  static const variable = 'wind_gusts_10m';
  static const timeStep = 'current_time_1H';

  /// Open-Meteo minimal style (official wind example).
  /// Slower on first WebView open.
  static const openMeteoStyleUrl =
      'https://map-assets.open-meteo.com/styles/minimal-planet-maps.json';

  /// Basemap shell must load before the map is interactive (not wind tiles).
  static const shellTimeout = Duration(seconds: 45);
}
