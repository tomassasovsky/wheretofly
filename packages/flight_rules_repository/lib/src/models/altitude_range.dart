import 'package:equatable/equatable.dart';
import 'package:flight_rules_repository/src/models/permission_level.dart';

/// Planned vertical extent of a flight (AGL), from takeoff through cruise.
class AltitudeRange extends Equatable {
  const AltitudeRange({
    required this.minMetersAgl,
    required this.maxMetersAgl,
  });

  final double minMetersAgl;
  final double maxMetersAgl;

  static const defaultMinMetersAgl = 0.0;

  /// ANAC open-category ceiling (m AGL).
  static const defaultMaxMetersAgl = 122.0;

  /// Maximum altitude for Specific Category / special-permit planning.
  static const maxPlanningAltitudeMetersAgl = 500.0;

  static const openCategoryDefault = AltitudeRange(
    minMetersAgl: defaultMinMetersAgl,
    maxMetersAgl: defaultMaxMetersAgl,
  );

  /// Clamps both ends to [0, maxCeilingMetersAgl] and ensures min ≤ max.
  AltitudeRange clampedTo(double maxCeilingMetersAgl) {
    final max = maxMetersAgl.clamp(0, maxCeilingMetersAgl).toDouble();
    final min = minMetersAgl.clamp(0, max).toDouble();
    return AltitudeRange(minMetersAgl: min, maxMetersAgl: max);
  }

  AltitudeRange clampedFor(PermissionLevel permission) =>
      clampedTo(permission.maxPlannedAltitudeMetersAgl);

  @override
  List<Object?> get props => [minMetersAgl, maxMetersAgl];
}
