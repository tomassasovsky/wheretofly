import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flight_rules_repository/src/models/permission_level.dart';
import 'package:flight_rules_repository/src/models/zone_category.dart';
import 'package:latlong2/latlong.dart';

/// Domain model: a circular geofenced area with a flight restriction.
class FlyZone extends Equatable {
  const FlyZone({
    required this.id,
    required this.name,
    required this.category,
    required this.center,
    required this.radiusMeters,
    required this.permissionsThatAllowFlight,
    required this.details,
    this.lowerLimitMetersAgl,
    this.upperLimitMetersAgl,
    this.lowerLimitMetersMsl,
    this.upperLimitMetersMsl,
  });

  final String id;
  final String name;
  final ZoneCategory category;
  final LatLng center;
  final double radiusMeters;

  /// The permission levels under which flight in this zone is allowed. An empty
  /// set means flight is never allowed here without a bespoke clearance.
  final Set<PermissionLevel> permissionsThatAllowFlight;

  final String details;

  final double? lowerLimitMetersAgl;
  final double? upperLimitMetersAgl;
  final double? lowerLimitMetersMsl;
  final double? upperLimitMetersMsl;

  bool get hasVerticalLimits =>
      lowerLimitMetersAgl != null ||
      upperLimitMetersAgl != null ||
      lowerLimitMetersMsl != null ||
      upperLimitMetersMsl != null;

  /// Whether [point] falls inside this zone (haversine distance).
  bool contains(LatLng point) => _distanceMeters(center, point) <= radiusMeters;

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
        permissionsThatAllowFlight,
        details,
        lowerLimitMetersAgl,
        upperLimitMetersAgl,
        lowerLimitMetersMsl,
        upperLimitMetersMsl,
      ];
}
