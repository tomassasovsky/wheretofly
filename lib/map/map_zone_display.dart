import 'dart:math' as math;

import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';

/// Filters and styles map overlays so dense urban areas stay readable.
abstract final class MapZoneDisplay {
  static const maxCircles = 300;
  // Country view can include every MADHEL aerodrome (~700); urban view caps
  // overlap for readability.
  static const maxCirclesWideView = 800;
  static const urbanZoomThreshold = 11.5;
  // Below the urban threshold (country/region view) hide only the smallest
  // footprints so the map stays readable; everything else is drawn.
  static const wideZoomMinRadiusMeters = 2000;

  /// Altitude ceiling (m AGL) for the render filter: the highest altitude any
  /// drone permit plans to. Zones floored above this never constrain a drone,
  /// so they are not drawn. Using the broadest drone ceiling guarantees the map
  /// never hides a zone an assessment (which clamps lower per permission) would
  /// still flag.
  static const altitudeCeilingMetersAgl =
      AltitudeRange.maxPlanningAltitudeMetersAgl;

  static bool isOpenAipZone(FlyZone zone) => zone.source == ZoneSource.openaip;

  static bool isMadhelAerodrome(FlyZone zone) =>
      zone.source == ZoneSource.madhel;

  static bool isOpenAipPolygon(FlyZone zone) =>
      isOpenAipZone(zone) &&
      zone.boundary != null &&
      zone.boundary!.length >= 3;

  static bool _isWideZoom(double zoom) => zoom < urbanZoomThreshold;

  /// Zones to draw for the current camera. Assessment uses the full dataset.
  static List<FlyZone> visibleZones({
    required List<FlyZone> zones,
    required MapVisibleBounds? bounds,
    required double zoom,
    Set<String> highlightIds = const {},
  }) {
    // Drop zones whose floor is above every drone ceiling; keep highlighted
    // zones and unknown-floor zones (unknown is never treated as high).
    var visible = zones
        .where(
          (z) =>
              highlightIds.contains(z.id) ||
              z.constrainsAltitudeBelow(altitudeCeilingMetersAgl),
        )
        .toList();
    if (bounds != null) {
      visible = visible.where((z) => _intersectsBounds(z, bounds)).toList();
    }

    visible = visible
        .where((z) => _isSignificantAtZoom(z, zoom, highlightIds))
        .toList();

    // OpenAIP polygons are vertex-exact and cheap to cull by bounds; draw all
    // of them and only cap point/circle zones for readability.
    final polygons = visible.where(isOpenAipPolygon).toList(growable: false);
    final circles = visible.where((z) => !isOpenAipPolygon(z)).toList();

    final cap = _maxCirclesForZoom(zoom);
    if (circles.length <= cap) return [...polygons, ...circles];

    circles.sort((a, b) {
      final aHighlight = highlightIds.contains(a.id);
      final bHighlight = highlightIds.contains(b.id);
      if (aHighlight != bHighlight) return aHighlight ? -1 : 1;
      final severity = _severity(b).compareTo(_severity(a));
      if (severity != 0) return severity;
      return b.radiusMeters.compareTo(a.radiusMeters);
    });
    return [...polygons, ...circles.take(cap)];
  }

  static int _maxCirclesForZoom(double zoom) =>
      _isWideZoom(zoom) ? maxCirclesWideView : maxCircles;

  static bool _isSignificantAtZoom(
    FlyZone zone,
    double zoom,
    Set<String> highlightIds,
  ) {
    if (highlightIds.contains(zone.id)) return true;
    if (isMadhelAerodrome(zone)) return true;
    if (isOpenAipPolygon(zone)) return true;
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

  static bool shouldFill(
    FlyZone zone, {
    required bool highlighted,
    double? zoom,
  }) {
    if (highlighted) return true;
    if (zoom != null && _isWideZoom(zoom) && isMadhelAerodrome(zone)) {
      return true;
    }
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
    double? zoom,
  }) {
    if (!shouldFill(zone, highlighted: highlighted, zoom: zoom)) return 0;
    if (highlighted) return isDark ? 0.28 : 0.18;
    if (zoom != null && _isWideZoom(zoom) && isMadhelAerodrome(zone)) {
      return 0.11;
    }
    return switch (zone.category) {
      ZoneCategory.prohibited => isDark ? 0.22 : 0.14,
      ZoneCategory.nationalPark => isDark ? 0.18 : 0.12,
      ZoneCategory.sensitiveInfrastructure => isDark ? 0.18 : 0.12,
      _ => isDark ? 0.16 : 0.10,
    };
  }

  static double strokeAlpha({
    required bool isDark,
    required bool highlighted,
    FlyZone? zone,
    double? zoom,
  }) {
    if (highlighted) return isDark ? 0.95 : 0.90;
    if (zone != null &&
        zoom != null &&
        _isWideZoom(zoom) &&
        isMadhelAerodrome(zone)) {
      return isDark ? 0.72 : 0.78;
    }
    // Light basemap: stronger strokes so rings read on pale land.
    return isDark ? 0.50 : 0.58;
  }

  static int strokeWidth({
    required bool highlighted,
    FlyZone? zone,
    double? zoom,
  }) {
    if (highlighted) return 2;
    if (zone != null &&
        zoom != null &&
        _isWideZoom(zoom) &&
        isMadhelAerodrome(zone)) {
      return 2;
    }
    return 1;
  }

  static int _severity(FlyZone zone) {
    if (isMadhelAerodrome(zone)) return 72;
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

  static bool _intersectsBounds(FlyZone zone, MapVisibleBounds bounds) {
    final sw = bounds.southWest;
    final ne = bounds.northEast;
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
