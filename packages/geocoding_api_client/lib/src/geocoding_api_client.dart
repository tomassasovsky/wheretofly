import 'dart:async';
import 'dart:convert';

import 'package:geocoding_api_client/src/models/geocode_result.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Data client for OpenStreetMap geocoding via the Photon API, biased to
/// Argentina. Photon handles partial/typeahead queries much better than raw
/// Nominatim search. No API key required.
class GeocodingApiClient {
  GeocodingApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _host = 'photon.komoot.io';
  static const _requestTimeout = Duration(seconds: 10);

  /// Argentina bounding box: minLon, minLat, maxLon, maxLat.
  static const _argentinaBbox = '-74,-56,-53,-21';

  /// Searches for [query] within Argentina, returning up to [limit] results.
  ///
  /// Throws [GeocodingException] with [GeocodingFailure.network] on a transport
  /// error and [GeocodingFailure.noResults] when nothing matches.
  Future<List<GeocodeResult>> search(String query, {int limit = 5}) async {
    final uri = Uri.https(_host, '/api/', {
      'q': query,
      'limit': '$limit',
      'bbox': _argentinaBbox,
    });

    final http.Response response;
    try {
      response = await _httpClient.get(
        uri,
        headers: const {
          'User-Agent': 'where_to_fly/1.0 (drone zone checker)',
        },
      ).timeout(_requestTimeout);
    } on TimeoutException {
      throw const GeocodingException(GeocodingFailure.network);
    } catch (_) {
      throw const GeocodingException(GeocodingFailure.network);
    }

    if (response.statusCode != 200) {
      throw const GeocodingException(GeocodingFailure.network);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GeocodingException(GeocodingFailure.network);
    }

    final features = decoded['features'];
    if (features is! List || features.isEmpty) {
      throw const GeocodingException(GeocodingFailure.noResults);
    }

    final results = features
        .whereType<Map<String, dynamic>>()
        .map(_parseFeature)
        .whereType<GeocodeResult>()
        .where((result) => _isInArgentina(result.point))
        .take(limit)
        .toList();

    if (results.isEmpty) {
      throw const GeocodingException(GeocodingFailure.noResults);
    }

    return results;
  }

  /// Reverse-geocodes [point] to the nearest address label in Argentina.
  ///
  /// Throws [GeocodingException] with [GeocodingFailure.network] on a transport
  /// error and [GeocodingFailure.noResults] when nothing matches.
  Future<GeocodeResult> reverse(LatLng point) async {
    final uri = Uri.https(_host, '/reverse', {
      'lon': '${point.longitude}',
      'lat': '${point.latitude}',
    });

    final http.Response response;
    try {
      response = await _httpClient.get(
        uri,
        headers: const {
          'User-Agent': 'where_to_fly/1.0 (drone zone checker)',
        },
      ).timeout(_requestTimeout);
    } on TimeoutException {
      throw const GeocodingException(GeocodingFailure.network);
    } catch (_) {
      throw const GeocodingException(GeocodingFailure.network);
    }

    if (response.statusCode != 200) {
      throw const GeocodingException(GeocodingFailure.network);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GeocodingException(GeocodingFailure.network);
    }

    final features = decoded['features'];
    if (features is! List || features.isEmpty) {
      throw const GeocodingException(GeocodingFailure.noResults);
    }

    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;
      final result = _parseFeature(feature);
      if (result != null && _isInArgentina(result.point)) {
        return result;
      }
    }

    throw const GeocodingException(GeocodingFailure.noResults);
  }

  static GeocodeResult? _parseFeature(Map<String, dynamic> feature) {
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

    return GeocodeResult(
      label: _formatLabel(props, fallback: feature['name'] as String?),
      point: LatLng(lat.toDouble(), lon.toDouble()),
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

  static bool _isInArgentina(LatLng point) =>
      point.latitude >= -56 &&
      point.latitude <= -21 &&
      point.longitude >= -74 &&
      point.longitude <= -53;
}
