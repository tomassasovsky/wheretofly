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
    this.polygon,
    this.lowerLimitMetersAgl,
    this.upperLimitMetersAgl,
    this.lowerLimitMetersMsl,
    this.upperLimitMetersMsl,
  });

  final String id;
  final String name;
  final String categoryId;

  /// Bounding-circle centre latitude. When [polygon] is set this is the
  /// approximate centroid; it is still used for culling and as a fallback.
  final double latitude;

  /// Bounding-circle centre longitude. See [latitude].
  final double longitude;

  /// Bounding-circle radius in metres. With [polygon] present this is the
  /// enclosing radius (used only for viewport culling and fallback rendering).
  final double radiusMeters;

  /// Exterior boundary ring as `[longitude, latitude]` pairs (GeoJSON order),
  /// when the source provides a real polygon. `null` for point-derived zones
  /// (aerodromes, bundled landmarks), which remain circular. The ring is not
  /// required to repeat its first point as the last.
  final List<List<double>>? polygon;

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
        polygon,
        allowedPermissionIds,
        details,
        lowerLimitMetersAgl,
        upperLimitMetersAgl,
        lowerLimitMetersMsl,
        upperLimitMetersMsl,
      ];
}
