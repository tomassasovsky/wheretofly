import 'dart:math' as math;

import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/openaip_altitude_parser.dart';
import 'package:zones_api_client/src/text_encoding.dart';
import 'package:zones_api_client/src/zone_permission_ids.dart';
import 'package:zones_api_client/src/zone_source_ids.dart';

/// Shared parsing for OpenAIP airspace records (REST API items and export
/// GeoJSON features).
abstract final class OpenAipAirspaceParser {
  /// OpenAIP airspace `type` codes that are not local drone restrictions
  /// (FIR/UIR/ADIZ, enroute structure, ATC sectors, nationwide limits).
  static const excludedTypes = {
    10, // FIR
    11, // UIR
    12, // ADIZ
    15, // Airway
    16, // Military Training Route
    19, // Protected Area (often very large)
    22, // Transponder Setting
    26, // Control Area (CTA)
    27, // ACC Sector
    29, // Low Altitude Overflight Restriction
    30, // Military Route
    31, // TSA/TRA Feeding Route
    32, // VFR Sector
    33, // FIS Sector
    34, // Lower Traffic Area
    35, // Upper Traffic Area
  };

  /// Parses a REST API item or ND-GeoJSON export feature into [ZoneData].
  static ZoneData? parseRecord({
    required Map<String, dynamic> properties,
    required Map<String, dynamic> geometry,
    double maxRadiusMeters = 250000,
  }) {
    final type = properties['type'];
    if (type is num && excludedTypes.contains(type.toInt())) return null;

    final points = _exteriorRing(geometry);
    if (points == null || points.isEmpty) return null;

    final lon = points.map((p) => p[0]).reduce((a, b) => a + b) / points.length;
    final lat = points.map((p) => p[1]).reduce((a, b) => a + b) / points.length;
    final radius =
        points.map((p) => _haversine(lat, lon, p[1], p[0])).reduce(math.max);
    final radiusMeters = radius < 500 ? 500.0 : radius;
    if (radiusMeters > maxRadiusMeters) return null;

    final id =
        'openaip_${properties['_id'] ?? properties['id'] ?? '${lat}_$lon'}';
    final name = repairUtf8Text((properties['name'] ?? 'Airspace').toString());
    final categoryId = _categoryFor(type, name);
    final altitude = OpenAipAltitudeLimits.fromAirspaceJson(properties);
    final allowedPermissionIds = _allowedPermissions(categoryId, name);

    return ZoneData(
      id: id,
      name: name,
      categoryId: categoryId,
      latitude: lat,
      longitude: lon,
      radiusMeters: radiusMeters,
      polygon: points,
      allowedPermissionIds: allowedPermissionIds,
      details: _detailsFor(name, altitude),
      lowerLimitMetersAgl: altitude.lowerMetersAgl,
      upperLimitMetersAgl: altitude.upperMetersAgl,
      lowerLimitMetersMsl: altitude.lowerMetersMsl,
      upperLimitMetersMsl: altitude.upperMetersMsl,
      source: ZoneSourceIds.openaip,
    );
  }

  static List<List<double>>? _exteriorRing(Map<String, dynamic> geometry) {
    final type = geometry['type'];
    final coords = geometry['coordinates'];
    if (coords is! List || coords.isEmpty) return null;

    List<dynamic>? ring;
    if (type == 'Polygon') {
      final first = coords.first;
      ring = first is List ? first : null;
    } else if (type == 'MultiPolygon') {
      final firstPoly = coords.first;
      if (firstPoly is List && firstPoly.isNotEmpty) {
        final firstRing = firstPoly.first;
        ring = firstRing is List ? firstRing : null;
      }
    }
    if (ring is! List || ring.length < 3) return null;

    final points = <List<double>>[];
    for (final c in ring) {
      if (c is List && c.length >= 2) {
        points.add([(c[0] as num).toDouble(), (c[1] as num).toDouble()]);
      }
    }
    return points.isEmpty ? null : points;
  }

  static String _detailsFor(String name, OpenAipAltitudeLimits altitude) {
    final buffer = StringBuffer('OpenAIP airspace ($name)');
    if (altitude.hasParsedLimits) {
      buffer.write('. Vertical limits: ${altitude.describe()}');
    }
    buffer.write('.');
    return buffer.toString();
  }

  static String _categoryFor(Object? type, String name) {
    final upper = name.toUpperCase();
    if (upper.startsWith('SAR ')) return 'restricted';
    if (RegExp(r'\b(CTR|ATZ|MATZ|MCTR|TMZ|RMZ|HTZ|TIZ|TIA)\b')
        .hasMatch(upper)) {
      return 'controlled_airspace';
    }
    if (RegExp(r'\bTMA\b').hasMatch(upper)) return 'controlled_airspace';
    if (upper.startsWith('SAP ')) return 'controlled_airspace';

    switch (type) {
      case 3: // Prohibited
        return 'prohibited';
      case 4: // CTR
      case 5: // TMZ
      case 6: // RMZ
      case 7: // TMA
      case 13: // ATZ
      case 14: // MATZ
      case 20: // HTZ
      case 23: // TIZ
      case 24: // TIA
      case 36: // MCTR
        return 'controlled_airspace';
      default:
        return 'restricted';
    }
  }

  static Set<String> _allowedPermissions(String categoryId, String name) {
    return switch (categoryId) {
      'prohibited' => ZonePermissionIds.none,
      'controlled_airspace' => ZonePermissionIds.controlledAirspace,
      'restricted' => ZonePermissionIds.controlledAirspace,
      _ => ZonePermissionIds.siteClearanceOnly,
    };
  }

  static double _haversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.asin(math.min(1, math.sqrt(a)));
  }
}
