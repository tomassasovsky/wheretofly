import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flight_rules_repository/src/models/permission_level.dart';
import 'package:flight_rules_repository/src/models/zone_category.dart';
import 'package:flight_rules_repository/src/models/zone_source.dart';
import 'package:latlong2/latlong.dart';

/// Domain model: a geofenced area with a flight restriction. The footprint is
/// the [boundary] polygon when present, otherwise a circle of [radiusMeters]
/// around [center].
class FlyZone extends Equatable {
  const FlyZone({
    required this.id,
    required this.name,
    required this.category,
    required this.center,
    required this.radiusMeters,
    required this.permissionsThatAllowFlight,
    required this.details,
    this.boundary,
    this.lowerLimitMetersAgl,
    this.upperLimitMetersAgl,
    this.lowerLimitMetersMsl,
    this.upperLimitMetersMsl,
    this.source = ZoneSource.bundled,
    this.confirmedBy,
    this.activeFrom,
    this.activeTo,
  });

  final String id;
  final String name;
  final ZoneCategory category;

  /// Bounding-circle centre. With [boundary] set this is the approximate
  /// centroid, retained for culling and as a circular fallback.
  final LatLng center;

  /// Bounding-circle radius in metres. See [center].
  final double radiusMeters;

  /// True boundary ring (exterior), or `null` for circular zones. Points are in
  /// order; the ring need not repeat its first vertex.
  final List<LatLng>? boundary;

  /// The permission levels under which flight in this zone is allowed. An empty
  /// set means flight is never allowed here without a bespoke clearance.
  final Set<PermissionLevel> permissionsThatAllowFlight;

  final String details;

  final double? lowerLimitMetersAgl;
  final double? upperLimitMetersAgl;
  final double? lowerLimitMetersMsl;
  final double? upperLimitMetersMsl;

  /// Where this zone's geometry originates. Defaults to [ZoneSource.bundled];
  /// the repository sets it from `ZoneData.source`.
  final ZoneSource source;

  /// A second source confirming this zone's identity/restriction (e.g. OpenAIP
  /// geometry confirmed by ANAC AIP), or `null` when single-sourced.
  final ZoneSource? confirmedBy;

  /// Start of the validity window (UTC) for time-bounded NOTAM zones, or `null`
  /// for permanent zones / an open-ended start.
  final DateTime? activeFrom;

  /// End of the validity window (UTC) for time-bounded NOTAM zones, or `null`
  /// for permanent zones / an open-ended end.
  final DateTime? activeTo;

  bool get hasVerticalLimits =>
      lowerLimitMetersAgl != null ||
      upperLimitMetersAgl != null ||
      lowerLimitMetersMsl != null ||
      upperLimitMetersMsl != null;

  /// Whether [point] falls inside this zone: point-in-polygon against
  /// [boundary] when present, otherwise haversine distance to [center].
  bool contains(LatLng point) {
    final ring = boundary;
    if (ring == null || ring.length < 3) {
      return _distanceMeters(center, point) <= radiusMeters;
    }
    return _pointInRing(point, ring);
  }

  /// Even-odd ray casting in lon/lat space. Adequate at zone scale, where the
  /// planar approximation error is far below the source data resolution.
  static bool _pointInRing(LatLng p, List<LatLng> ring) {
    final x = p.longitude;
    final y = p.latitude;
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i].longitude;
      final yi = ring[i].latitude;
      final xj = ring[j].longitude;
      final yj = ring[j].latitude;
      final intersects =
          (yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi;
      if (intersects) inside = !inside;
    }
    return inside;
  }

  /// Whether any part of [[minAgl], [maxAgl]] overlaps this zone vertically.
  bool overlapsAltitudeRange(
    double minAgl,
    double maxAgl, {
    double groundElevationMslMeters = 0,
  }) {
    if (!hasVerticalLimits) return true;
    final minMsl = minAgl + groundElevationMslMeters;
    final maxMsl = maxAgl + groundElevationMslMeters;

    if (lowerLimitMetersAgl != null || upperLimitMetersAgl != null) {
      if (!_intervalsOverlap(
        minAgl,
        maxAgl,
        lowerLimitMetersAgl ?? 0,
        upperLimitMetersAgl ?? double.infinity,
      )) {
        return false;
      }
    }
    if (lowerLimitMetersMsl != null || upperLimitMetersMsl != null) {
      if (!_intervalsOverlap(
        minMsl,
        maxMsl,
        lowerLimitMetersMsl ?? 0,
        upperLimitMetersMsl ?? double.infinity,
      )) {
        return false;
      }
    }
    return true;
  }

  static bool _intervalsOverlap(
    double aMin,
    double aMax,
    double bMin,
    double bMax,
  ) =>
      aMin <= bMax && bMin <= aMax;

  /// Whether a pilot holding [permission] may fly inside this zone.
  bool allowsFlightFor(PermissionLevel permission) =>
      permissionsThatAllowFlight.contains(permission);

  static double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    return earthRadius * 2 * math.asin(math.min(1, math.sqrt(h)));
  }

  static double _toRad(double deg) => deg * (math.pi / 180.0);

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        center.latitude,
        center.longitude,
        radiusMeters,
        boundary,
        permissionsThatAllowFlight,
        details,
        lowerLimitMetersAgl,
        upperLimitMetersAgl,
        lowerLimitMetersMsl,
        upperLimitMetersMsl,
        source,
        confirmedBy,
        activeFrom,
        activeTo,
      ];
}
