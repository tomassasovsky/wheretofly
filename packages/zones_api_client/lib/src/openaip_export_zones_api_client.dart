import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/openaip_airspace_parser.dart';

/// Thrown when the OpenAIP daily country export cannot be fetched or parsed.
class OpenAipExportException implements Exception {
  const OpenAipExportException(this.message);
  final String message;
  @override
  String toString() => 'OpenAipExportException: $message';
}

/// Loads airspaces from OpenAIP's public daily ND-GeoJSON country export.
///
/// No API key is required. Files are published to the OpenAIP GCS bucket and
/// updated daily (see https://www.openaip.net/data/exports).
class OpenAipExportZonesApiClient {
  OpenAipExportZonesApiClient({
    this.country = 'ar',
    this.maxRadiusMeters = 250000,
    http.Client? httpClient,
    Uri? exportUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _exportUrl = exportUrl ??
            Uri.parse(
              'https://storage.googleapis.com/'
              '29f98e10-a489-4c82-ae5e-489dbcd4912f/${country}_asp.ndgeojson',
            );

  final String country;
  final double maxRadiusMeters;
  final Uri _exportUrl;
  final http.Client _httpClient;

  Future<List<ZoneData>> fetchZones() async {
    final http.Response response;
    try {
      response = await _httpClient.get(_exportUrl).timeout(
            const Duration(seconds: 30),
          );
    } catch (e) {
      throw OpenAipExportException('network error: $e');
    }
    if (response.statusCode != 200) {
      throw OpenAipExportException('HTTP ${response.statusCode}');
    }

    final zones = <ZoneData>[];
    for (final line in const LineSplitter().convert(response.body)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) continue;
      final properties = decoded['properties'];
      final geometry = decoded['geometry'];
      if (properties is! Map<String, dynamic> ||
          geometry is! Map<String, dynamic>) {
        continue;
      }

      final zone = OpenAipAirspaceParser.parseRecord(
        properties: properties,
        geometry: geometry,
        maxRadiusMeters: maxRadiusMeters,
      );
      if (zone != null) zones.add(zone);
    }

    if (zones.isEmpty) {
      throw const OpenAipExportException('no airspaces in export');
    }
    return zones;
  }
}
