import 'package:argentina_bounds/argentina_bounds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/map_theme.dart';

/// Shared map defaults before the platform map layer is shown.
abstract final class MapInitializer {
  static const argentinaCenter = LatLng(-38.4161, -63.6167);

  /// Geographic extent used for zoom limits and initial camera fit.
  static LatLngBounds get argentinaBounds {
    final e = ArgentinaBounds.geographicExtent;
    return LatLngBounds(
      LatLng(e.minLat, e.minLon),
      LatLng(e.maxLat, e.maxLon),
    );
  }

  /// Placeholder behind the map while tiles load (see MapTheme.placeholderFor).
  static Color placeholderColorFor(Brightness brightness) =>
      MapTheme.placeholderFor(brightness);

  /// Resolves map appearance from in-app [ThemeMode], not only [Theme].
  static Brightness mapBrightnessFor(
    BuildContext context,
    ThemeMode themeMode,
  ) {
    return switch (themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
  }

  static String mapTileTemplateFor(Brightness brightness) =>
      MapTheme.tileUrlTemplateFor(brightness);

  /// No-op — flutter_map initializes with the first map widget.
  static Future<void> initializePlatform() async {}
}
