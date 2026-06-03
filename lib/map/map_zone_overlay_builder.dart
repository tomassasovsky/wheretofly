import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/map_zone_display.dart';
import 'package:where_to_fly/theme/app_theme.dart';

/// Builds Google Maps circles and markers from [MapState].
abstract final class MapZoneOverlayBuilder {
  static Set<gmaps.Circle> circles(
    MapState state, {
    required gmaps.LatLngBounds? visibleBounds,
    required double zoom,
    required bool isDark,
  }) {
    final highlightIds = {
      ...?state.assessment?.zones.map((z) => z.id),
      ...?state.assessment?.skippedByAltitude.map((z) => z.id),
    };
    final visible = MapZoneDisplay.visibleZones(
      zones: state.zones,
      bounds: visibleBounds,
      zoom: zoom,
      highlightIds: highlightIds,
    );

    return visible.map((zone) {
      final highlighted = highlightIds.contains(zone.id);
      final color = AppTheme.zoneColor(zone.category);
      final fillAlpha = MapZoneDisplay.fillAlpha(
        zone,
        isDark: isDark,
        highlighted: highlighted,
      );
      final strokeAlpha = MapZoneDisplay.strokeAlpha(
        isDark: isDark,
        highlighted: highlighted,
      );
      return gmaps.Circle(
        circleId: gmaps.CircleId(zone.id),
        center: _toGoogle(zone.center),
        radius: zone.radiusMeters,
        fillColor: color.withValues(alpha: fillAlpha),
        strokeColor: color.withValues(alpha: strokeAlpha),
        strokeWidth: MapZoneDisplay.strokeWidth(highlighted: highlighted),
      );
    }).toSet();
  }

  static Set<gmaps.Marker> markers(MapState state) {
    final point = state.selectedPoint;
    if (point == null) return const {};
    return {
      gmaps.Marker(
        markerId: const gmaps.MarkerId('selected'),
        position: _toGoogle(point),
      ),
    };
  }

  static gmaps.LatLng _toGoogle(LatLng point) =>
      gmaps.LatLng(point.latitude, point.longitude);
}
