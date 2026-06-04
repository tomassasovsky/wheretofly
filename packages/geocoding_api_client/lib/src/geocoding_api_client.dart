import 'dart:async';
import 'dart:convert';

import 'package:geocoding_api_client/src/models/geocode_result.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Data client for map geocoding via the Dónde Volar backend (Photon proxy).
class GeocodingApiClient {
  GeocodingApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final Uri baseUrl;
  final http.Client _httpClient;

  static const _requestTimeout = Duration(seconds: 12);

  /// Searches for [query] within Argentina, returning up to [limit] results.
  ///
  /// Throws [GeocodingException] with [GeocodingFailure.network] on a transport
  /// error and [GeocodingFailure.noResults] when nothing matches.
  Future<List<GeocodeResult>> search(String query, {int limit = 5}) async {
    final uri = baseUrl.replace(
      path: '/v1/geocoding/search',
      queryParameters: {
        'q': query,
        'limit': '$limit',
      },
    );

    final response = await _get(uri);
    if (response.statusCode == 404) {
      throw const GeocodingException(GeocodingFailure.noResults);
    }
    if (response.statusCode != 200) {
      throw const GeocodingException(GeocodingFailure.network);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GeocodingException(GeocodingFailure.network);
    }

    final results = decoded['results'];
    if (results is! List || results.isEmpty) {
      throw const GeocodingException(GeocodingFailure.noResults);
    }

    final parsed = results
        .whereType<Map<String, dynamic>>()
        .map(_parseHit)
        .whereType<GeocodeResult>()
        .take(limit)
        .toList();

    if (parsed.isEmpty) {
      throw const GeocodingException(GeocodingFailure.noResults);
    }
    return parsed;
  }

  /// Reverse-geocodes [point] to the nearest address label in Argentina.
  ///
  /// Throws [GeocodingException] with [GeocodingFailure.network] on a transport
  /// error and [GeocodingFailure.noResults] when nothing matches.
  Future<GeocodeResult> reverse(LatLng point) async {
    final uri = baseUrl.replace(
      path: '/v1/geocoding/reverse',
      queryParameters: {
        'lat': '${point.latitude}',
        'lon': '${point.longitude}',
      },
    );

    final response = await _get(uri);
    if (response.statusCode == 404) {
      throw const GeocodingException(GeocodingFailure.noResults);
    }
    if (response.statusCode != 200) {
      throw const GeocodingException(GeocodingFailure.network);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GeocodingException(GeocodingFailure.network);
    }

    final result = _parseHit(decoded);
    if (result == null) {
      throw const GeocodingException(GeocodingFailure.noResults);
    }
    return result;
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _httpClient.get(uri).timeout(_requestTimeout);
    } on TimeoutException {
      throw const GeocodingException(GeocodingFailure.network);
    } catch (_) {
      throw const GeocodingException(GeocodingFailure.network);
    }
  }

  GeocodeResult? _parseHit(Map<String, dynamic> hit) {
    final label = hit['label'];
    final lat = hit['latitude'];
    final lon = hit['longitude'];
    if (label is! String || lat is! num || lon is! num) return null;
    return GeocodeResult(
      label: label,
      point: LatLng(lat.toDouble(), lon.toDouble()),
    );
  }
}
