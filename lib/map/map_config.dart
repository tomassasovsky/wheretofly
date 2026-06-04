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
  static const tileUserAgentPackageName = 'dev.aquiles.where_to_fly';

  /// Resolves the basemap tile URL template for [brightness].
  static String tileUrlTemplateFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? cartoDarkMatterTileUrl
        : cartoVoyagerTileUrl;
  }
}
