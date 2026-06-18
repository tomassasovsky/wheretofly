import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/map_theme.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/map_zone_overlay_builder.dart';

/// Zone overlays split by geometry: polygon-backed zones render as exact
/// [Polygon]s (vertex-faithful), point-backed zones as true-meter
/// [CircleMarker]s. Both scale correctly while zooming.
typedef MapZoneLayers = ({List<Polygon> polygons, List<CircleMarker> circles});

abstract final class MapZoneFlutterMapMarkers {
  static MapZoneLayers build({
    required MapState state,
    required MapVisibleBounds? visibleBounds,
    required double zoom,
    required bool isDark,
    required Brightness brightness,
  }) {
    final styles = MapZoneOverlayBuilder.circles(
      state,
      visibleBounds: visibleBounds,
      zoom: zoom,
      isDark: isDark,
    );

    final polygons = <Polygon>[];
    final circles = <CircleMarker>[];
    for (final style in styles) {
      final ring = style.boundary;
      if (ring != null && ring.length >= 3) {
        polygons.add(
          Polygon(
            points: ring,
            color: style.fillColor,
            borderColor: style.strokeColor,
            borderStrokeWidth: style.strokeWidth.toDouble(),
          ),
        );
      } else {
        circles.add(
          CircleMarker(
            point: style.center,
            radius: style.radiusMeters,
            useRadiusInMeter: true,
            color: style.fillColor,
            borderColor: style.strokeColor,
            borderStrokeWidth: style.strokeWidth.toDouble(),
          ),
        );
      }
    }

    final selected = MapZoneOverlayBuilder.selectedPoint(state);
    if (selected != null) {
      circles.add(
        CircleMarker(
          point: selected,
          radius: 10,
          color: MapTheme.selectionFillFor(brightness),
          borderColor: MapTheme.selectionStrokeFor(brightness),
          borderStrokeWidth: 3,
        ),
      );
    }

    return (polygons: polygons, circles: circles);
  }
}
