import 'dart:math' as math;

import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

/// Filters and styles map overlays so dense urban areas stay readable.
abstract final class MapZoneDisplay {
  static const maxCircles = 300;
  static const urbanZoomThreshold = 11.5;
  // Below the urban threshold (country/region view) hide only the smallest
  // footprints so the map stays readable; everything else is drawn.
  static const wideZoomMinRadiusMeters = 2000;

  /// Zones to draw for the current camera. Assessment uses the full dataset.
  static List<FlyZone> visibleZones({
    required List<FlyZone> zones,
    required gmaps.LatLngBounds? bounds,
    required double zoom,
    Set<String> highlightIds = const {},
  }) {
    var visible = zones;
    if (bounds != null) {
      visible = visible.where((z) => _intersectsBounds(z, bounds)).toList();
    }

    visible = visible
        .where((z) => _isSignificantAtZoom(z, zoom, highlightIds))
        .toList();

    if (visible.length <= maxCircles) return visible;

    visible.sort((a, b) {
      final aHighlight = highlightIds.contains(a.id);
      final bHighlight = highlightIds.contains(b.id);
      if (aHighlight != bHighlight) return aHighlight ? -1 : 1;
      final severity = _severity(b).compareTo(_severity(a));
      if (severity != 0) return severity;
      return b.radiusMeters.compareTo(a.radiusMeters);
    });
    return visible.take(maxCircles).toList();
  }

  static bool _isSignificantAtZoom(
    FlyZone zone,
    double zoom,
    Set<String> highlightIds,
  ) {
    if (highlightIds.contains(zone.id)) return true;
    if (_alwaysDraw(zone)) return true;

    // Only thin out the smallest footprints at country/region zoom; from the
    // urban threshold up, every zone is drawn (subject to [maxCircles]).
    if (zoom < urbanZoomThreshold) {
      return zone.radiusMeters >= wideZoomMinRadiusMeters;
    }
    return true;
  }

  static bool _alwaysDraw(FlyZone zone) {
    return switch (zone.category) {
      ZoneCategory.prohibited ||
      ZoneCategory.nationalPark ||
      ZoneCategory.sensitiveInfrastructure =>
        true,
      _ => false,
    };
  }

  static bool shouldFill(FlyZone zone, {required bool highlighted}) {
    if (highlighted) return true;
    return switch (zone.category) {
      ZoneCategory.prohibited ||
      ZoneCategory.nationalPark ||
      ZoneCategory.sensitiveInfrastructure =>
        true,
      _ => false,
    };
  }

  static double fillAlpha(
    FlyZone zone, {
    required bool isDark,
    required bool highlighted,
  }) {
    if (!shouldFill(zone, highlighted: highlighted)) return 0;
    if (highlighted) return isDark ? 0.28 : 0.18;
    return switch (zone.category) {
      ZoneCategory.prohibited => isDark ? 0.22 : 0.14,
      ZoneCategory.nationalPark => isDark ? 0.18 : 0.12,
      ZoneCategory.sensitiveInfrastructure => isDark ? 0.18 : 0.12,
      _ => isDark ? 0.16 : 0.10,
    };
  }

  static double strokeAlpha({required bool isDark, required bool highlighted}) {
    if (highlighted) return isDark ? 0.95 : 0.85;
    return isDark ? 0.30 : 0.22;
  }

  static int strokeWidth({required bool highlighted}) => highlighted ? 3 : 1;

  static int _severity(FlyZone zone) {
    if (zone.permissionsThatAllowFlight.isEmpty) return 100;
    return switch (zone.category) {
      ZoneCategory.prohibited => 90,
      ZoneCategory.sensitiveInfrastructure => 80,
      ZoneCategory.nationalPark => 70,
      ZoneCategory.controlledAirspace => 60,
      ZoneCategory.restricted => 50,
      ZoneCategory.open => 10,
    };
  }

  static bool _intersectsBounds(FlyZone zone, gmaps.LatLngBounds bounds) {
    final sw = bounds.southwest;
    final ne = bounds.northeast;
    final latMargin = zone.radiusMeters / 111000;
    final lonMargin = zone.radiusMeters /
        (111000 * math.cos(zone.center.latitude * math.pi / 180));

    final minLat = zone.center.latitude - latMargin;
    final maxLat = zone.center.latitude + latMargin;
    final minLon = zone.center.longitude - lonMargin;
    final maxLon = zone.center.longitude + lonMargin;

    return maxLat >= sw.latitude &&
        minLat <= ne.latitude &&
        maxLon >= sw.longitude &&
        minLon <= ne.longitude;
  }
}
