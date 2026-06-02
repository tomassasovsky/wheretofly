import 'package:equatable/equatable.dart';

/// Raw data-transfer object for a flight-restriction zone.
///
/// This is a *data layer* model: it uses primitive types and string ids only,
/// with no knowledge of the app's domain enums. The repository maps it to a
/// domain model.
class ZoneData extends Equatable {
  const ZoneData({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.allowedPermissionIds,
    required this.details,
    this.lowerLimitMetersAgl,
    this.upperLimitMetersAgl,
    this.lowerLimitMetersMsl,
    this.upperLimitMetersMsl,
  });

  final String id;
  final String name;
  final String categoryId;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  /// Ids of the permission levels that allow flight in this zone.
  final Set<String> allowedPermissionIds;

  final String details;

  /// Vertical limits from OpenAIP (optional). When all null, the zone applies
  /// at every altitude inside the horizontal circle.
  final double? lowerLimitMetersAgl;
  final double? upperLimitMetersAgl;
  final double? lowerLimitMetersMsl;
  final double? upperLimitMetersMsl;

  bool get hasVerticalLimits =>
      lowerLimitMetersAgl != null ||
      upperLimitMetersAgl != null ||
      lowerLimitMetersMsl != null ||
      upperLimitMetersMsl != null;

  @override
  List<Object?> get props => [
        id,
        name,
        categoryId,
        latitude,
        longitude,
        radiusMeters,
        allowedPermissionIds,
        details,
        lowerLimitMetersAgl,
        upperLimitMetersAgl,
        lowerLimitMetersMsl,
        upperLimitMetersMsl,
      ];
}
