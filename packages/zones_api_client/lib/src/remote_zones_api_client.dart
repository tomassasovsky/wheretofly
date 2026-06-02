import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zones_api_client/src/models/zone_data.dart';
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
/// Expects a GeoJSON `FeatureCollection` of `Point` features. Each feature's
/// `properties` should contain: `id`, `name`, `categoryId`, `radiusMeters`,
/// `details`, and `allowedPermissionIds` (a list of permission id strings).
/// Geometry coordinates are `[longitude, latitude]` per the GeoJSON spec.
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
    final coords = geometry['coordinates'];
    if (coords is! List || coords.length < 2) return null;

    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();

    final permissions = (props['allowedPermissionIds'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        const <String>{};

    return ZoneData(
      id: (props['id'] ?? feature['id'] ?? '').toString(),
      name: (props['name'] ?? '').toString(),
      categoryId: (props['categoryId'] ?? 'restricted').toString(),
      latitude: lat,
      longitude: lon,
      radiusMeters: (props['radiusMeters'] as num?)?.toDouble() ?? 3000,
      allowedPermissionIds: permissions,
      details: (props['details'] ?? '').toString(),
      lowerLimitMetersAgl: _optionalDouble(props['lowerLimitMetersAgl']),
      upperLimitMetersAgl: _optionalDouble(props['upperLimitMetersAgl']),
      lowerLimitMetersMsl: _optionalDouble(props['lowerLimitMetersMsl']),
      upperLimitMetersMsl: _optionalDouble(props['upperLimitMetersMsl']),
    );
  }

  double? _optionalDouble(Object? value) =>
      value == null ? null : (value as num).toDouble();
}
