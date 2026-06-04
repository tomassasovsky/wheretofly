import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/map_zone_circle_style.dart';
import 'package:where_to_fly/map/map_zone_display.dart';
import 'package:where_to_fly/theme/app_theme.dart';

/// Builds platform-neutral zone circle styles from [MapState].
abstract final class MapZoneOverlayBuilder {
  static List<MapZoneCircleStyle> circles(
    MapState state, {
    required MapVisibleBounds? visibleBounds,
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
        zoom: zoom,
      );
      final strokeAlpha = MapZoneDisplay.strokeAlpha(
        isDark: isDark,
        highlighted: highlighted,
        zone: zone,
        zoom: zoom,
      );
      return MapZoneCircleStyle(
        id: zone.id,
        center: zone.center,
        radiusMeters: zone.radiusMeters,
        fillColor: color.withValues(alpha: fillAlpha),
        strokeColor: color.withValues(alpha: strokeAlpha),
        strokeWidth: MapZoneDisplay.strokeWidth(
          highlighted: highlighted,
          zone: zone,
          zoom: zoom,
        ),
      );
    }).toList();
  }

  static LatLng? selectedPoint(MapState state) => state.selectedPoint;
}
