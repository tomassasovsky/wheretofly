import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/openaip_altitude_parser.dart';
import 'package:zones_api_client/src/zone_permission_ids.dart';

/// Thrown when the OpenAIP airspace feed cannot be fetched or parsed.
class OpenAipException implements Exception {
  const OpenAipException(this.message);
  final String message;
  @override
  String toString() => 'OpenAipException: $message';
}

/// Data client that loads airspaces from the OpenAIP API and adapts them to
/// the app's circular [ZoneData] model.
///
/// OpenAIP returns polygonal airspaces; this client approximates each as a
/// circle (centroid + enclosing radius). It complements the self-hosted
/// GeoJSON feed (which also covers parks, government and infrastructure that
/// OpenAIP does not).
///
/// Requires an OpenAIP API key (https://www.openaip.net/, free tier available).
class OpenAipZonesApiClient {
  OpenAipZonesApiClient({
    required this.apiKey,
    this.country = 'AR',
    this.limit = 1000,
    this.maxRadiusMeters = 80000,
    http.Client? httpClient,
    Uri? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl =
            baseUrl ?? Uri.parse('https://api.core.openaip.net/api/airspaces');

  final String apiKey;
  final String country;
  final int limit;

  /// Airspaces whose approximated circle would be larger than this are dropped.
  /// This filters out country-sized regions (FIR/UIR/ADIZ) that are not local
  /// drone restrictions.
  final double maxRadiusMeters;

  final Uri _baseUrl;
  final http.Client _httpClient;

  /// OpenAIP airspace `type` codes that are not local drone restrictions
  /// (FIR/UIR/ADIZ, enroute structure, ATC sectors, nationwide limits).
  static const _excludedTypes = {
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

  Future<List<ZoneData>> fetchZones() async {
    final uri = _baseUrl.replace(
      queryParameters: {
        'country': country,
        'limit': '$limit',
      },
    );

    final http.Response response;
    try {
      response = await _httpClient.get(
        uri,
        headers: {'x-openaip-api-key': apiKey},
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw OpenAipException('network error: $e');
    }
    if (response.statusCode != 200) {
      throw OpenAipException('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final items = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    if (items is! List) {
      throw const OpenAipException('unexpected response shape');
    }

    final zones = <ZoneData>[];
    for (final item in items.whereType<Map<String, dynamic>>()) {
      if (_excludedTypes.contains(item['type'])) continue;
      final zone = _parse(item);
      if (zone != null) zones.add(zone);
    }
    return zones;
  }

  ZoneData? _parse(Map<String, dynamic> item) {
    final geometry = item['geometry'];
    if (geometry is! Map<String, dynamic>) return null;
    final coords = geometry['coordinates'];
    // Polygon: [ [ [lon,lat], ... ] ]
    if (coords is! List || coords.isEmpty) return null;
    final ring = coords.first;
    if (ring is! List || ring.length < 3) return null;

    final points = <List<double>>[];
    for (final c in ring) {
      if (c is List && c.length >= 2) {
        points.add([(c[0] as num).toDouble(), (c[1] as num).toDouble()]);
      }
    }
    if (points.isEmpty) return null;

    final lon = points.map((p) => p[0]).reduce((a, b) => a + b) / points.length;
    final lat = points.map((p) => p[1]).reduce((a, b) => a + b) / points.length;
    final radius =
        points.map((p) => _haversine(lat, lon, p[1], p[0])).reduce(math.max);
    final radiusMeters = radius < 500 ? 500.0 : radius;
    if (radiusMeters > maxRadiusMeters) return null;

    final id = 'openaip_${item['_id'] ?? item['id'] ?? '${lat}_$lon'}';
    final name = (item['name'] ?? 'Airspace').toString();
    final categoryId = _categoryFor(item['type'], name);
    final altitude = OpenAipAltitudeLimits.fromAirspaceJson(item);

    final allowedPermissionIds = _allowedPermissions(categoryId, name);

    return ZoneData(
      id: id,
      name: name,
      categoryId: categoryId,
      latitude: lat,
      longitude: lon,
      radiusMeters: radiusMeters,
      allowedPermissionIds: allowedPermissionIds,
      details: _detailsFor(name, altitude),
      lowerLimitMetersAgl: altitude.lowerMetersAgl,
      upperLimitMetersAgl: altitude.upperMetersAgl,
      lowerLimitMetersMsl: altitude.lowerMetersMsl,
      upperLimitMetersMsl: altitude.upperMetersMsl,
    );
  }

  static String _detailsFor(String name, OpenAipAltitudeLimits altitude) {
    final buffer = StringBuffer('OpenAIP airspace ($name)');
    if (altitude.hasParsedLimits) {
      buffer.write('. Vertical limits parsed from OpenAIP');
    }
    buffer.write('.');
    return buffer.toString();
  }

  static String _categoryFor(Object? type, String name) {
    final upper = name.toUpperCase();
    // Argentina AIP: SAR = restricted area (Zona Restringida), not prohibited.
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

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
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
