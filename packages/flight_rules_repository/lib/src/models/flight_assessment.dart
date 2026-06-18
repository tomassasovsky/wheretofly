import 'package:equatable/equatable.dart';
import 'package:flight_rules_repository/src/models/altitude_range.dart';
import 'package:flight_rules_repository/src/models/flight_modality.dart';
import 'package:flight_rules_repository/src/models/fly_zone.dart';
import 'package:flight_rules_repository/src/models/permission_level.dart';
import 'package:flight_rules_repository/src/models/zone_category.dart';

/// Legacy 3-value verdict for a location, permission level and flight modality.
///
/// Kept as a compatibility type only. New presentation code should switch on
/// [FlightAssessment.status] (the confidence-aware authority), not on this
/// enum. Only the social wire format still reads the derived
/// [FlightAssessment.verdict].
enum FlightVerdict { allowed, allowedWithPermission, notAllowed }

/// Confidence-aware verdict status. The verdict authority going forward.
enum VerdictStatus { allowed, conditional, blocked, uncertain }

/// Typed, l10n-keyed reasons a verdict carries. Future accuracy axes ADD their
/// own value (e.g. `coarseTerrainData`, `nearBoundaryGpsBuffer`,
/// `notamSnapshotStale`) in the PR that emits it — adding a [VerdictReason]
/// value later costs ZERO consumer re-migration because presentation switches
/// on [VerdictStatus], not on [VerdictReason].
enum VerdictReason {
  /// Repository was built from an empty zone list — no data to stand on.
  zoneDataUnavailable,

  /// An overlapping zone uses MSL limits without known ground elevation.
  mslGroundElevationUnknown,
}

/// The result of evaluating a point against the zone dataset for a given
/// [permission], [modality], and planned altitude.
class FlightAssessment extends Equatable {
  FlightAssessment({
    required this.permission,
    required this.modality,
    required this.status,
    required this.modalityAllowed,
    required this.altitudeRange,
    required this.zones,
    this.skippedByAltitude = const [],
    List<VerdictReason> reasons = const [],
  }) : reasons = List.unmodifiable(reasons);

  static const maxOpenCategoryAltitudeMetersAgl =
      AltitudeRange.defaultMaxMetersAgl;

  static const maxPlanningAltitudeMetersAgl =
      AltitudeRange.maxPlanningAltitudeMetersAgl;

  final PermissionLevel permission;
  final FlightModality modality;

  /// Confidence-aware verdict status — the authority for this assessment.
  final VerdictStatus status;

  /// Typed reasons this verdict carries (deduped, unmodifiable). Future
  /// accuracy layers append a reason and downgrade [status] without
  /// re-migrating consumers.
  final List<VerdictReason> reasons;

  /// Back-compat: legacy 3-value verdict derived from [status].
  ///
  /// `uncertain` maps to `notAllowed` (conservative) for old readers ONLY.
  FlightVerdict get verdict => switch (status) {
        VerdictStatus.allowed => FlightVerdict.allowed,
        VerdictStatus.conditional => FlightVerdict.allowedWithPermission,
        VerdictStatus.blocked => FlightVerdict.notAllowed,
        VerdictStatus.uncertain => FlightVerdict.notAllowed,
      };

  /// Whether the held [permission] is sufficient for the chosen [modality]
  /// (independent of location). When false, flight is blocked everywhere.
  final bool modalityAllowed;

  /// Planned flight altitude band above ground (takeoff through cruise).
  final AltitudeRange altitudeRange;

  /// Zones that horizontally contain the point and overlap [altitudeRange].
  final List<FlyZone> zones;

  /// Horizontally inside but no vertical overlap with [altitudeRange].
  final List<FlyZone> skippedByAltitude;

  /// True when the verdict carries the MSL ground-elevation uncertainty reason.
  /// Drives the existing MSL disclaimer banner — now sourced from [reasons].
  bool get hasMslAltitudeUncertainty =>
      reasons.contains(VerdictReason.mslGroundElevationUnknown);

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
        status,
        reasons,
        modalityAllowed,
        altitudeRange,
        zones,
        skippedByAltitude,
      ];
}
