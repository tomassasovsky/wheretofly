import 'package:flutter/material.dart';
import 'package:where_to_fly/map/map_config.dart';

/// Map basemap and overlay styling aligned with the app Material theme.
abstract final class MapTheme {
  static const lightStyleUrl = MapConfig.cartoVoyagerStyleUrl;
  static const darkStyleUrl = MapConfig.cartoDarkMatterStyleUrl;

  /// Shown behind the map while the style loads (matches basemap land color).
  static const lightPlaceholder = Color(0xFFF4F1EC);

  /// Matches CARTO Dark Matter background.
  static const darkPlaceholder = Color(0xFF0D0D0D);

  static String tileUrlTemplateFor(Brightness brightness) =>
      MapConfig.tileUrlTemplateFor(brightness);

  /// MapLibre style URL (wind WebView only).
  static String styleUrlFor(Brightness brightness) =>
      MapConfig.styleUrlFor(brightness);

  static Color placeholderFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkPlaceholder : lightPlaceholder;

  /// Tap / search selection marker (app seed purple / light blue on dark).
  static Color selectionFillFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF5E9EFF)
          : const Color(0xFF3B0297);

  static const Color selectionStroke = Colors.white;
}
