part of 'map_cubit.dart';

/// State for the map screen.
class MapState extends Equatable {
  const MapState({
    this.permission = PermissionLevel.recreational,
    this.modality = FlightModality.vlos,
    this.altitudeRange = AltitudeRange.openCategoryDefault,
    this.zones = const [],
    this.selectedPoint,
    this.assessment,
  });

  /// The permission level the user has selected they hold.
  final PermissionLevel permission;

  /// The flight modality the user intends to fly.
  final FlightModality modality;

  /// Planned altitude band (m AGL): takeoff through cruise.
  final AltitudeRange altitudeRange;

  /// All zones to draw on the map.
  final List<FlyZone> zones;

  /// The point the user tapped to check (if any).
  final LatLng? selectedPoint;

  /// The assessment for [selectedPoint] under [permission]/[modality] (if any).
  final FlightAssessment? assessment;

  MapState copyWith({
    PermissionLevel? permission,
    FlightModality? modality,
    AltitudeRange? altitudeRange,
    List<FlyZone>? zones,
    LatLng? selectedPoint,
    FlightAssessment? assessment,
    bool clearSelection = false,
  }) {
    return MapState(
      permission: permission ?? this.permission,
      modality: modality ?? this.modality,
      altitudeRange: altitudeRange ?? this.altitudeRange,
      zones: zones ?? this.zones,
      selectedPoint:
          clearSelection ? null : (selectedPoint ?? this.selectedPoint),
      assessment: clearSelection ? null : (assessment ?? this.assessment),
    );
  }

  @override
  List<Object?> get props => [
        permission,
        modality,
        altitudeRange,
        zones,
        selectedPoint,
        assessment,
      ];
}
