import 'package:equatable/equatable.dart';
import 'package:flight_rules_repository/src/models/altitude_range.dart';
import 'package:flight_rules_repository/src/models/flight_modality.dart';
import 'package:flight_rules_repository/src/models/fly_zone.dart';
import 'package:flight_rules_repository/src/models/permission_level.dart';
import 'package:flight_rules_repository/src/models/zone_category.dart';

/// The verdict for a given location, permission level and flight modality.
enum FlightVerdict { allowed, allowedWithPermission, notAllowed }

/// The result of evaluating a point against the zone dataset for a given
/// [permission], [modality], and planned altitude.
class FlightAssessment extends Equatable {
  const FlightAssessment({
    required this.permission,
    required this.modality,
    required this.verdict,
    required this.modalityAllowed,
    required this.altitudeRange,
    required this.zones,
    this.skippedByAltitude = const [],
  });

  static const maxOpenCategoryAltitudeMetersAgl =
      AltitudeRange.defaultMaxMetersAgl;

  static const maxPlanningAltitudeMetersAgl =
      AltitudeRange.maxPlanningAltitudeMetersAgl;

  final PermissionLevel permission;
  final FlightModality modality;
  final FlightVerdict verdict;

  /// Whether the held [permission] is sufficient for the chosen [modality]
  /// (independent of location). When false, flight is blocked everywhere.
  final bool modalityAllowed;

  /// Planned flight altitude band above ground (takeoff through cruise).
  final AltitudeRange altitudeRange;

  /// Zones that horizontally contain the point and overlap [altitudeRange].
  final List<FlyZone> zones;

  /// Horizontally inside but no vertical overlap with [altitudeRange].
  final List<FlyZone> skippedByAltitude;

  /// True when any overlapping zone uses MSL limits without terrain elevation.
  bool get hasMslAltitudeUncertainty => [
        ...zones,
        ...skippedByAltitude,
      ].any(
        (z) => z.lowerLimitMetersMsl != null || z.upperLimitMetersMsl != null,
      );

  /// Zones the held permission does NOT cover (the location blockers).
  List<FlyZone> get blockingZones =>
      zones.where((z) => !z.allowsFlightFor(permission)).toList();

  /// Whether any overlapping zone is controlled airspace (ATC coordination).
  bool get hasControlledAirspaceZones =>
      zones.any((z) => z.category == ZoneCategory.controlledAirspace);

  /// The lowest permission that satisfies [modality] and every overlapping
  /// [zones] entry. Null when flight is not possible with any standard
  /// authorization (for example, a prohibited zone).
  PermissionLevel? get minimumRequiredPermission {
    final floor = modality.minimumPermission;

    Set<PermissionLevel>? allowed;
    for (final zone in zones) {
      if (zone.permissionsThatAllowFlight.isEmpty) return null;
      allowed = allowed == null
          ? zone.permissionsThatAllowFlight
          : allowed.intersection(zone.permissionsThatAllowFlight);
      if (allowed.isEmpty) return null;
    }

    final candidates = (allowed ?? PermissionLevel.values.toSet())
        .where((p) => p.rank >= floor.rank);
    if (candidates.isEmpty) return null;

    return candidates.reduce((a, b) => a.rank <= b.rank ? a : b);
  }

  @override
  List<Object?> get props => [
        permission,
        modality,
        verdict,
        modalityAllowed,
        altitudeRange,
        zones,
        skippedByAltitude,
      ];
}
