import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/map_theme.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/map_zone_overlay_builder.dart';

/// Builds [CircleMarker]s with true meter radius (scales while zooming).
abstract final class MapZoneFlutterMapMarkers {
  static List<CircleMarker> build({
    required MapState state,
    required MapVisibleBounds? visibleBounds,
    required double zoom,
    required bool isDark,
    required Brightness brightness,
  }) {
    final circleStyles = MapZoneOverlayBuilder.circles(
      state,
      visibleBounds: visibleBounds,
      zoom: zoom,
      isDark: isDark,
    );

    final markers = <CircleMarker>[
      for (final style in circleStyles)
        CircleMarker(
          point: style.center,
          radius: style.radiusMeters,
          useRadiusInMeter: true,
          color: style.fillColor,
          borderColor: style.strokeColor,
          borderStrokeWidth: style.strokeWidth.toDouble(),
        ),
    ];

    final selected = MapZoneOverlayBuilder.selectedPoint(state);
    if (selected != null) {
      markers.add(
        CircleMarker(
          point: selected,
          radius: 10,
          color: MapTheme.selectionFillFor(brightness),
          borderColor: MapTheme.selectionStrokeFor(brightness),
          borderStrokeWidth: 3,
        ),
      );
    }

    return markers;
  }
}
