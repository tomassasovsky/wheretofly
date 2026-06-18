import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/text_encoding.dart';
import 'package:zones_api_client/src/zone_source_ids.dart';
import 'package:zones_api_client/src/zone_time.dart';
import 'package:zones_api_client/src/zones_feed_client.dart';

/// Thrown when the remote zones feed cannot be fetched or parsed.
class RemoteZonesException implements Exception {
  const RemoteZonesException(this.message);
  final String message;
  @override
  String toString() => 'RemoteZonesException: $message';
}

/// Data client that loads the authoritative zone feed at runtime.
///
/// Expects a GeoJSON `FeatureCollection` of `Point` or `Polygon` features.
/// Each feature's `properties` should contain: `id`, `name`, `categoryId`,
/// `radiusMeters`, `details`, and `allowedPermissionIds` (a list of permission
/// id strings); polygon features should also carry `latitude`/`longitude` for
/// the bounding-circle centre. Coordinates are `[longitude, latitude]` per the
/// GeoJSON spec; `Polygon` rings are preserved in [ZoneData.polygon] for
/// vertex-exact rendering and containment.
///
/// Point this at an official ANAC/AIP-derived GeoJSON export to make the app a
/// live source of truth; otherwise the app uses `BundledZonesApiClient`.
class RemoteZonesApiClient implements ZonesFeedClient {
  RemoteZonesApiClient({required this.url, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// The URL of the GeoJSON zones feed.
  final Uri url;

  final http.Client _httpClient;

  @override
  Future<List<ZoneData>> fetchZones() async {
    final http.Response response;
    try {
      response = await _httpClient.get(url).timeout(const Duration(seconds: 8));
    } catch (e) {
      throw RemoteZonesException('network error: $e');
    }
    if (response.statusCode != 200) {
      throw RemoteZonesException('HTTP ${response.statusCode}');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw RemoteZonesException('invalid JSON: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const RemoteZonesException('expected a GeoJSON object');
    }
    final features = decoded['features'];
    if (features is! List) {
      throw const RemoteZonesException('missing features array');
    }

    final zones = <ZoneData>[];
    for (final feature in features.whereType<Map<String, dynamic>>()) {
      final zone = _parseFeature(feature);
      if (zone != null) zones.add(zone);
    }
    if (zones.isEmpty) {
      throw const RemoteZonesException('no zones in feed');
    }
    return zones;
  }

  ZoneData? _parseFeature(Map<String, dynamic> feature) {
    final props = feature['properties'];
    final geometry = feature['geometry'];
    if (props is! Map<String, dynamic> || geometry is! Map<String, dynamic>) {
      return null;
    }

    final polygon = _parsePolygon(geometry);
    final center = _parseCenter(geometry, props, polygon);
    if (center == null) return null;
    final (lat, lon) = center;
    final id = (props['id'] ?? feature['id'] ?? '').toString();

    final permissions = (props['allowedPermissionIds'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        const <String>{};

    return ZoneData(
      id: id,
      name: repairUtf8Text((props['name'] ?? '').toString()),
      categoryId: (props['categoryId'] ?? 'restricted').toString(),
      latitude: lat,
      longitude: lon,
      radiusMeters: (props['radiusMeters'] as num?)?.toDouble() ?? 3000,
      polygon: polygon,
      allowedPermissionIds: permissions,
      details: repairUtf8Text((props['details'] ?? '').toString()),
      lowerLimitMetersAgl: _optionalDouble(props['lowerLimitMetersAgl']),
      upperLimitMetersAgl: _optionalDouble(props['upperLimitMetersAgl']),
      lowerLimitMetersMsl: _optionalDouble(props['lowerLimitMetersMsl']),
      upperLimitMetersMsl: _optionalDouble(props['upperLimitMetersMsl']),
      source: (props['source'] as String?) ?? ZoneSourceIds.fromIdPrefix(id),
      confirmedBy: props['confirmedBy'] as String?,
      activeFrom: parseUtcDateTime(props['activeFrom']),
      activeTo: parseUtcDateTime(props['activeTo']),
    );
  }

  /// Exterior ring as `[lon, lat]` pairs, or `null` for non-polygon geometry.
  List<List<double>>? _parsePolygon(Map<String, dynamic> geometry) {
    if (geometry['type'] != 'Polygon') return null;
    final coords = geometry['coordinates'];
    if (coords is! List || coords.isEmpty) return null;
    final ring = coords.first;
    if (ring is! List || ring.length < 3) return null;
    final out = <List<double>>[];
    for (final p in ring) {
      if (p is List && p.length >= 2) {
        out.add([(p[0] as num).toDouble(), (p[1] as num).toDouble()]);
      }
    }
    return out.length < 3 ? null : out;
  }

  /// Bounding-circle centre as `(lat, lon)`: explicit properties, then a Point
  /// geometry, then the polygon centroid.
  (double, double)? _parseCenter(
    Map<String, dynamic> geometry,
    Map<String, dynamic> props,
    List<List<double>>? polygon,
  ) {
    final propLat = _optionalDouble(props['latitude']);
    final propLon = _optionalDouble(props['longitude']);
    if (propLat != null && propLon != null) return (propLat, propLon);

    final coords = geometry['coordinates'];
    if (geometry['type'] == 'Point' && coords is List && coords.length >= 2) {
      return ((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
    }

    if (polygon != null && polygon.isNotEmpty) {
      final lon =
          polygon.map((p) => p[0]).reduce((a, b) => a + b) / polygon.length;
      final lat =
          polygon.map((p) => p[1]).reduce((a, b) => a + b) / polygon.length;
      return (lat, lon);
    }
    return null;
  }

  double? _optionalDouble(Object? value) =>
      value == null ? null : (value as num).toDouble();
}
