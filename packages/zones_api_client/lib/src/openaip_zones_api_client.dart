import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/openaip_airspace_parser.dart';

/// Thrown when the OpenAIP airspace feed cannot be fetched or parsed.
class OpenAipException implements Exception {
  const OpenAipException(this.message);
  final String message;
  @override
  String toString() => 'OpenAipException: $message';
}

/// Data client that loads airspaces from the OpenAIP REST API and adapts them
/// to the app's [ZoneData] model.
///
/// OpenAIP returns polygonal airspaces; this client preserves the full boundary
/// ring in [ZoneData.polygon] and additionally derives a bounding circle
/// (centroid + enclosing radius) used for viewport culling and as a fallback.
///
/// For bulk country ingest without an API key, prefer
/// [OpenAipExportZonesApiClient].
///
/// Requires an OpenAIP API key (https://www.openaip.net/, free tier available).
class OpenAipZonesApiClient {
  OpenAipZonesApiClient({
    required this.apiKey,
    this.country = 'AR',
    this.pageSize = 500,
    this.maxRadiusMeters = 250000,
    http.Client? httpClient,
    Uri? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl =
            baseUrl ?? Uri.parse('https://api.core.openaip.net/api/airspaces');

  final String apiKey;
  final String country;
  final int pageSize;
  final double maxRadiusMeters;

  final Uri _baseUrl;
  final http.Client _httpClient;

  Future<List<ZoneData>> fetchZones() async {
    final zones = <ZoneData>[];
    var page = 1;

    while (true) {
      final uri = _baseUrl.replace(
        queryParameters: {
          'country': country,
          'limit': '$pageSize',
          'page': '$page',
        },
      );

      final http.Response response;
      try {
        response = await _httpClient.get(
          uri,
          headers: {'x-openaip-api-key': apiKey},
        ).timeout(const Duration(seconds: 15));
      } catch (e) {
        throw OpenAipException('network error: $e');
      }
      if (response.statusCode != 200) {
        throw OpenAipException('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final items =
          decoded is Map<String, dynamic> ? decoded['items'] : decoded;
      if (items is! List) {
        throw const OpenAipException('unexpected response shape');
      }

      if (items.isEmpty) break;

      for (final item in items.whereType<Map<String, dynamic>>()) {
        final geometry = item['geometry'];
        if (geometry is! Map<String, dynamic>) continue;
        final zone = OpenAipAirspaceParser.parseRecord(
          properties: item,
          geometry: geometry,
          maxRadiusMeters: maxRadiusMeters,
        );
        if (zone != null) zones.add(zone);
      }

      if (items.length < pageSize) break;
      page++;
    }

    return zones;
  }
}
