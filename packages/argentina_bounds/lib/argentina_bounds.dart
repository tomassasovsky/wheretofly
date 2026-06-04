import 'package:argentina_bounds/argentina_border_path.dart';
import 'package:argentina_bounds/neighbor_exclusions.dart';
import 'package:argentina_bounds/point_in_polygon.dart';
import 'package:latlong2/latlong.dart';

/// Whether a WGS84 point lies inside Argentina (Natural Earth 10m ADM0 paths).
abstract final class ArgentinaBounds {
  /// Strict check: Natural Earth border paths only.
  static bool containsPrecise(LatLng point) =>
      containsPreciseCoords(point.latitude, point.longitude);

  static bool containsPreciseCoords(double lat, double lon) {
    if (!_extentContains(lat, lon)) return false;
    return pointInAnyRing(lat, lon, ArgentinaBorderPath.allRings);
  }

  /// Map selection: precise paths, plus inclusive fallback for NE gaps.
  static bool contains(LatLng point) =>
      containsCoords(point.latitude, point.longitude);

  static bool containsCoords(double lat, double lon) {
    if (containsPreciseCoords(lat, lon)) return true;
    return _inclusiveFallback(lat, lon);
  }

  /// Wider coverage when NE polygons miss Argentine territory (e.g. some
  /// Tierra del Fuego localities). Still excludes Uruguay, Paraguay, and Chile.
  static bool _inclusiveFallback(double lat, double lon) {
    if (lat < -55.5 || lat > -21.3 || lon < -73.8 || lon > -53.0) {
      return false;
    }
    if (pointInPolygonRing(lat, lon, NeighborExclusions.uruguay)) return false;
    if (pointInPolygonRing(lat, lon, NeighborExclusions.paraguay)) return false;
    if (pointInPolygonRing(lat, lon, NeighborExclusions.chile)) return false;
    return true;
  }

  static bool _extentContains(double lat, double lon) {
    final e = _extent;
    return lat >= e.minLat &&
        lat <= e.maxLat &&
        lon >= e.minLon &&
        lon <= e.maxLon;
  }

  /// Axis-aligned bounding box of the Natural Earth border paths (WGS84).
  static ({double minLat, double maxLat, double minLon, double maxLon})
      get geographicExtent {
    final e = _extent;
    return (
      minLat: e.minLat,
      maxLat: e.maxLat,
      minLon: e.minLon,
      maxLon: e.maxLon,
    );
  }

  static _Extent? _cachedExtent;

  static _Extent get _extent {
    final cached = _cachedExtent;
    if (cached != null) return cached;

    var minLat = 90.0;
    var maxLat = -90.0;
    var minLon = 180.0;
    var maxLon = -180.0;
    for (final ring in ArgentinaBorderPath.allRings) {
      for (final v in ring) {
        if (v.$1 < minLat) minLat = v.$1;
        if (v.$1 > maxLat) maxLat = v.$1;
        if (v.$2 < minLon) minLon = v.$2;
        if (v.$2 > maxLon) maxLon = v.$2;
      }
    }
    return _cachedExtent = _Extent(
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
    );
  }
}

final class _Extent {
  const _Extent({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
}
