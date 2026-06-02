import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zones_api_client/src/madhel_zone_mapper.dart';
import 'package:zones_api_client/src/models/zone_data.dart';

/// Thrown when the ANAC MADHEL aerodrome feed cannot be fetched or parsed.
class MadhelException implements Exception {
  const MadhelException(this.message);
  final String message;
  @override
  String toString() => 'MadhelException: $message';
}

/// Data client for the official ANAC MADHEL aerodrome and heliport catalog.
///
/// API docs: https://ais.anac.gob.ar/madhel/
/// Endpoint: https://datos.anac.gob.ar/madhel/api/v2/airports/
class MadhelZonesApiClient {
  MadhelZonesApiClient({
    http.Client? httpClient,
    Uri? baseUrl,
    this.timeout = const Duration(seconds: 15),
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ??
            Uri.parse('https://datos.anac.gob.ar/madhel/api/v2/airports/');

  final http.Client _httpClient;
  final Uri _baseUrl;
  final Duration timeout;

  Future<List<ZoneData>> fetchZones() async {
    final http.Response response;
    try {
      response = await _httpClient.get(_baseUrl).timeout(timeout);
    } catch (e) {
      throw MadhelException('network error: $e');
    }

    if (response.statusCode != 200) {
      throw MadhelException('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const MadhelException('unexpected response shape');
    }

    final results = decoded['results'];
    if (results is! List) {
      throw const MadhelException('missing results array');
    }

    final zones = <ZoneData>[];
    for (final entry in results) {
      if (entry is! Map<String, dynamic>) continue;
      final zone = MadhelZoneMapper.fromListEntry(entry);
      if (zone != null) zones.add(zone);
    }

    if (zones.isEmpty) {
      throw const MadhelException('empty aerodrome catalog');
    }

    return zones;
  }
}
