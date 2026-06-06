import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:storage/storage.dart';
import 'package:zones_api_client/zones_api_client.dart';

/// Loads zones from the Dónde Volar backend (`GET /v1/zones`) with ETag
/// caching and offline fallback to the last cached GeoJSON body.
class BackendZonesApiClient implements ZonesFeedClient {
  BackendZonesApiClient({
    required this.baseUrl,
    required this.storage,
    this.accessTokenProvider,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  static const _etagKey = 'zone_feed_etag';
  static const _bodyKey = 'zone_feed_body';
  static const _versionKey = 'zone_feed_version';
  static const _updatedAtKey = 'zone_feed_updated_at';

  final Uri baseUrl;
  final Future<String?> Function()? accessTokenProvider;
  final Storage storage;
  final http.Client _httpClient;

  ZoneFeedMetadata get lastMetadata {
    final version = storage.read(_versionKey);
    final updatedRaw = storage.read(_updatedAtKey);
    final updatedAt = updatedRaw == null ? null : DateTime.tryParse(updatedRaw);
    return ZoneFeedMetadata(
      version: version,
      updatedAt: updatedAt,
      etag: storage.read(_etagKey),
    );
  }

  @override
  Future<List<ZoneData>> fetchZones() async {
    final token =
        accessTokenProvider == null ? null : await accessTokenProvider!();

    final uri = baseUrl.replace(path: '/v1/zones');
    final etag = storage.read(_etagKey);
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
      if (etag != null) 'If-None-Match': etag,
    };

    http.Response response;
    try {
      response = await _httpClient
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      return _parseCachedBody();
    } catch (_) {
      return _parseCachedBody();
    }

    if (response.statusCode == 304) {
      return _parseCachedBody();
    }
    if (response.statusCode != 200) {
      return _parseCachedBody();
    }

    final newEtag = response.headers['etag'] ?? response.headers['ETag'];
    final version = response.headers['x-zone-version'] ??
        response.headers['X-Zone-Version'];
    final updatedAtHeader = response.headers['x-zone-updated-at'] ??
        response.headers['X-Zone-Updated-At'];

    if (newEtag != null) await storage.write(_etagKey, newEtag);
    if (version != null) await storage.write(_versionKey, version);
    if (updatedAtHeader != null) {
      await storage.write(_updatedAtKey, updatedAtHeader);
    }
    await storage.write(_bodyKey, response.body);

    return _parseGeoJson(response.body);
  }

  Future<List<ZoneData>> _parseCachedBody() async {
    final cached = storage.read(_bodyKey);
    if (cached == null || cached.isEmpty) return const [];
    try {
      return _parseGeoJson(cached);
    } catch (_) {
      return const [];
    }
  }

  List<ZoneData> _parseGeoJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const RemoteZonesException('expected a GeoJSON object');
    }
    final features = decoded['features'];
    if (features is! List) {
      throw const RemoteZonesException('missing features array');
    }

    final parser = _GeoJsonFeatureParser();
    final zones = <ZoneData>[];
    for (final feature in features.whereType<Map<String, dynamic>>()) {
      final zone = parser.parseFeature(feature);
      if (zone != null) zones.add(zone);
    }
    if (zones.isEmpty) {
      throw const RemoteZonesException('no zones in feed');
    }
    return zones;
  }
}

/// Shared GeoJSON point-feature parsing for remote feeds.
class _GeoJsonFeatureParser {
  ZoneData? parseFeature(Map<String, dynamic> feature) {
    final props = feature['properties'];
    final geometry = feature['geometry'];
    if (props is! Map<String, dynamic> || geometry is! Map<String, dynamic>) {
      return null;
    }

    final polygon = _parsePolygon(geometry);
    final center = _parseCenter(geometry, props, polygon);
    if (center == null) return null;
    final (lat, lon) = center;

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
      polygon: polygon,
      allowedPermissionIds: permissions,
      details: (props['details'] ?? '').toString(),
      lowerLimitMetersAgl: _optionalDouble(props['lowerLimitMetersAgl']),
      upperLimitMetersAgl: _optionalDouble(props['upperLimitMetersAgl']),
      lowerLimitMetersMsl: _optionalDouble(props['lowerLimitMetersMsl']),
      upperLimitMetersMsl: _optionalDouble(props['upperLimitMetersMsl']),
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

  /// Bounding-circle centre as `(lat, lon)`. Prefers explicit properties, then
  /// Point geometry, then the polygon centroid.
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
