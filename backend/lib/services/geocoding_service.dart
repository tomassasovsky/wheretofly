import 'dart:async';
import 'dart:convert';

import 'package:backend/config/app_config.dart';
import 'package:http/http.dart' as http;

/// Proxies OpenStreetMap geocoding via a self-hosted Photon instance.
class GeocodingService {
  /// Creates a geocoding service with an optional HTTP client for tests.
  GeocodingService({
    required AppConfig config,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client(),
       _photonBase = _normalizePhotonBase(config.photonBaseUrl);

  final http.Client _httpClient;
  final String _photonBase;

  static const _requestTimeout = Duration(seconds: 10);
  static const _argentinaBbox = '-74,-56,-53,-21';

  static String _normalizePhotonBase(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return 'http://localhost:2322';
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  /// Searches for [query] within Argentina, returning up to [limit] results.
  Future<List<GeocodeHit>> search(String query, {int limit = 5}) async {
    final uri = _photonUri(
      '/api/',
      {
        'q': query,
        'limit': '$limit',
        'bbox': _argentinaBbox,
      },
    );

    final response = await _get(uri);
    final features = _readFeatures(response);
    final results = features
        .map(_parseFeature)
        .whereType<GeocodeHit>()
        .take(limit)
        .toList();

    if (results.isEmpty) {
      throw const GeocodingServiceException('no results');
    }
    return results;
  }

  /// Reverse-geocodes [lat]/[lon] to the nearest address label in Argentina.
  Future<GeocodeHit> reverse({
    required double lat,
    required double lon,
  }) async {
    final uri = _photonUri(
      '/reverse',
      {
        'lon': '$lon',
        'lat': '$lat',
      },
    );

    final response = await _get(uri);
    final features = _readFeatures(response);
    for (final feature in features) {
      final result = _parseFeature(feature);
      if (result != null) return result;
    }
    throw const GeocodingServiceException('no results');
  }

  Uri _photonUri(String path, Map<String, String> query) {
    final base = Uri.parse(_photonBase);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: normalizedPath,
      queryParameters: query,
    );
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      final response = await _httpClient
          .get(
            uri,
            headers: const {
              'User-Agent': 'dondevolar-backend/1.0 (drone zone checker)',
            },
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw const GeocodingServiceException('upstream error');
      }
      return response;
    } on TimeoutException {
      throw const GeocodingServiceException('upstream timeout');
    } on GeocodingServiceException {
      rethrow;
    } on Object {
      throw const GeocodingServiceException('upstream error');
    }
  }

  List<Map<String, dynamic>> _readFeatures(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GeocodingServiceException('invalid upstream response');
    }
    final features = decoded['features'];
    if (features is! List || features.isEmpty) {
      throw const GeocodingServiceException('no results');
    }
    return features.whereType<Map<String, dynamic>>().toList();
  }

  GeocodeHit? _parseFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    if (geometry is! Map<String, dynamic>) return null;

    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;

    final lon = coordinates[0];
    final lat = coordinates[1];
    if (lon is! num || lat is! num) return null;

    final properties = feature['properties'];
    final props = properties is Map<String, dynamic> ? properties : null;
    final countryCode = props?['countrycode'] as String?;
    if (countryCode != null && countryCode.toUpperCase() != 'AR') {
      return null;
    }

    return GeocodeHit(
      label: _formatLabel(props, fallback: feature['name'] as String?),
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
    );
  }

  static String _formatLabel(
    Map<String, dynamic>? properties, {
    String? fallback,
  }) {
    if (properties == null) return fallback ?? '';

    final parts = <String>[];
    final name = (properties['name'] as String?)?.trim();
    final streetAddress = _streetAddress(properties);

    if (name != null &&
        name.isNotEmpty &&
        streetAddress.isNotEmpty &&
        streetAddress != name &&
        !streetAddress.contains(name)) {
      parts
        ..add(name)
        ..add(streetAddress);
    } else if (streetAddress.isNotEmpty) {
      parts.add(streetAddress);
    } else if (name != null && name.isNotEmpty) {
      parts.add(name);
    }

    for (final key in ['district', 'city', 'county', 'state', 'postcode']) {
      final value = (properties[key] as String?)?.trim();
      if (value != null && value.isNotEmpty && !parts.contains(value)) {
        parts.add(value);
      }
    }

    if (parts.isEmpty) return fallback ?? '';
    return parts.join(', ');
  }

  static String _streetAddress(Map<String, dynamic> properties) {
    final number = properties['housenumber']?.toString().trim();
    final street = (properties['street'] as String?)?.trim();
    if (street != null && number != null && number.isNotEmpty) {
      return '$street $number';
    }
    return street ?? '';
  }
}

/// A geocoding hit returned by [GeocodingService].
class GeocodeHit {
  /// Creates a geocoding hit with the given label, latitude, and longitude.
  const GeocodeHit({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  /// The human-readable label for the geocoding hit.
  final String label;

  /// The latitude of the geocoding hit.
  final double latitude;

  /// The longitude of the geocoding hit.
  final double longitude;

  /// Serializes the geocoding hit to a JSON map.
  Map<String, Object?> toJson() => {
    'label': label,
    'latitude': latitude,
    'longitude': longitude,
  };
}

/// Thrown when geocoding fails upstream or returns no matches.
class GeocodingServiceException implements Exception {
  /// Creates a geocoding service exception with the given message.
  const GeocodingServiceException(this.message);

  /// The message of the geocoding service exception.
  final String message;

  @override
  String toString() => 'GeocodingServiceException: $message';
}
