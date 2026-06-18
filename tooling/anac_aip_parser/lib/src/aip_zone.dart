/// Raw AIP entry for one airspace unit, before geometry is computed.
class AipZoneEntry {
  const AipZoneEntry({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.boundaryText,
    required this.allowedPermissionIds,
    required this.details,
    this.lowerLimitMetersAgl,
    this.upperLimitMetersAgl,
    this.lowerLimitMetersMsl,
    this.upperLimitMetersMsl,
  });

  final String id;
  final String name;

  /// Same category IDs used in [ZoneData] / the live feed.
  final String categoryId;

  /// The literal AIP lateral-limits text (Spanish), fed to [BoundaryParser].
  final String boundaryText;

  final Set<String> allowedPermissionIds;
  final String details;
  final double? lowerLimitMetersAgl;
  final double? upperLimitMetersAgl;
  final double? lowerLimitMetersMsl;
  final double? upperLimitMetersMsl;
}
