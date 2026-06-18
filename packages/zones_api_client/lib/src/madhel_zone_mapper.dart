import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/zone_permission_ids.dart';
import 'package:zones_api_client/src/zone_source_ids.dart';

/// Maps ANAC MADHEL aerodrome/heliport records to [ZoneData] circles.
///
/// Source: https://datos.anac.gob.ar/madhel/api/v2/airports/
class MadhelZoneMapper {
  const MadhelZoneMapper._();

  /// Parses one entry from the MADHEL list (`results[]`) response.
  static ZoneData? fromListEntry(Map<String, dynamic> entry) {
    final localId = entry['local_identifier'];
    if (localId is! String || localId.isEmpty) return null;

    final rawName = entry['human_readable_identifier'];
    final name = rawName is String && rawName.isNotEmpty ? rawName : localId;

    final geometry = entry['the_geom'];
    if (geometry is! Map<String, dynamic>) return null;
    final geom = geometry['geometry'];
    if (geom is! Map<String, dynamic>) return null;
    final coordinates = geom['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;

    final lon = _toDouble(coordinates[0]);
    final lat = _toDouble(coordinates[1]);
    if (lon == null || lat == null) return null;

    final upper = name.toUpperCase();
    if (upper.contains('CLSD') || upper.contains('CERRADO')) return null;

    final profile = _profileFor(name, localId);

    return ZoneData(
      id: 'madhel_$localId',
      name: name,
      categoryId: profile.categoryId,
      latitude: lat,
      longitude: lon,
      radiusMeters: profile.radiusMeters,
      allowedPermissionIds: profile.allowedPermissionIds,
      details: profile.details,
      source: ZoneSourceIds.madhel,
    );
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  static _MadhelProfile _profileFor(String name, String localId) {
    final upper = name.toUpperCase();
    final isHeliport = upper.contains('HELIPUERTO');
    final isUncontrolled = upper.contains('NO CONTROLADO');
    final isControlled = !isUncontrolled && upper.contains('CONTROLADO');

    if (isHeliport) {
      return _MadhelProfile(
        categoryId: 'controlled_airspace',
        radiusMeters: isControlled ? 3000 : 2000,
        allowedPermissionIds: ZonePermissionIds.controlledAirspace,
        details: 'Helipuerto registrado en MADHEL (ANAC). '
            'Verifique restricciones y coordine con el aeródromo '
            'o proveedor ATS antes de volar.',
      );
    }

    if (isControlled) {
      return const _MadhelProfile(
        categoryId: 'controlled_airspace',
        radiusMeters: 9000,
        allowedPermissionIds: ZonePermissionIds.controlledAirspace,
        details: 'Espacio aéreo controlado de aeródromo (MADHEL/ANAC). '
            'Requiere coordinación con la torre de control (ATC).',
      );
    }

    return const _MadhelProfile(
      categoryId: 'restricted',
      radiusMeters: 2500,
      allowedPermissionIds: ZonePermissionIds.controlledAirspace,
      details: 'Aeródromo registrado en MADHEL (ANAC), no controlado. '
          'Verifique NOTAMs/AIP y coordine según RAAC 100 antes de volar.',
    );
  }

  /// Parses a bundled snapshot JSON list (same shape as list API `results`).
  static List<ZoneData> fromSnapshotJson(List<dynamic> entries) {
    final zones = <ZoneData>[];
    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) continue;
      final zone = fromListEntry(entry);
      if (zone != null) zones.add(zone);
    }
    return zones;
  }
}

class _MadhelProfile {
  const _MadhelProfile({
    required this.categoryId,
    required this.radiusMeters,
    required this.allowedPermissionIds,
    required this.details,
  });

  final String categoryId;
  final double radiusMeters;
  final Set<String> allowedPermissionIds;
  final String details;
}
