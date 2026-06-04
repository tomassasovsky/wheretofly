import 'package:flutter/material.dart';

/// Map tile configuration for flutter_map.
abstract final class MapConfig {
  /// CARTO Voyager raster tiles.
  static const cartoVoyagerTileUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';

  /// CARTO Dark Matter raster tiles.
  static const cartoDarkMatterTileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';

  static const cartoSubdomains = ['a', 'b', 'c', 'd'];

  /// TileLayer user-agent package name (required on some platforms).
  static const tileUserAgentPackageName = 'com.example.where_to_fly';

  /// Resolves the basemap tile URL template for [brightness].
  ///
  /// Override at build time for MapTiler or self-hosted raster templates.
  /// For Spanish labels on the map (e.g. Islas Malvinas), use a provider that
  /// supports `language=es` (MapTiler, Mapbox GL, etc.) — CARTO Voyager uses
  /// default OSM English names baked into raster tiles.
  ///
  ///   flutter run --dart-define=MAP_TILE_URL_LIGHT=https://...
  ///   flutter run --dart-define=MAP_TILE_URL_DARK=https://...
  static String tileUrlTemplateFor(Brightness brightness) {
    const lightUrl = String.fromEnvironment(
      'MAP_TILE_URL_LIGHT',
      defaultValue: cartoVoyagerTileUrl,
    );
    const darkUrl = String.fromEnvironment(
      'MAP_TILE_URL_DARK',
      defaultValue: cartoDarkMatterTileUrl,
    );
    return brightness == Brightness.dark ? darkUrl : lightUrl;
  }

  /// Legacy MapLibre style URLs (wind WebView shell only).
  static const cartoVoyagerStyleUrl =
      'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json';

  static const cartoDarkMatterStyleUrl =
      'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';

  static String styleUrlFor(Brightness brightness) {
    const lightUrl = String.fromEnvironment(
      'MAP_STYLE_URL_LIGHT',
      defaultValue: cartoVoyagerStyleUrl,
    );
    const darkUrl = String.fromEnvironment(
      'MAP_STYLE_URL_DARK',
      defaultValue: cartoDarkMatterStyleUrl,
    );
    return brightness == Brightness.dark ? darkUrl : lightUrl;
  }
}
