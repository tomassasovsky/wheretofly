import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:where_to_fly/map/wind_map_config.dart';

/// Prefetches Open-Meteo spatial metadata in Dart before WebView init.
class WindMapOmUrlResolver {
  WindMapOmUrlResolver({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Returns the `latest.json` URL passed to `om://` in the WebView.
  Future<String> resolve({
    String model = WindMapConfig.model,
    String variable = WindMapConfig.variable,
    String timeStep = WindMapConfig.timeStep,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = Uri.https(
      'map-tiles.open-meteo.com',
      '/data_spatial/$model/latest.json',
      {'time_step': timeStep, 'variable': variable},
    );
    final response = await _client.get(uri).timeout(timeout);
    if (response.statusCode != 200) {
      throw WindMapResolveException(
        WindMapResolveCode.metadataFailed,
        statusCode: response.statusCode,
      );
    }

    final meta = jsonDecode(response.body) as Map<String, dynamic>;
    final variables = meta['variables'];
    if (variables is List &&
        variables.isNotEmpty &&
        !variables.contains(variable)) {
      throw const WindMapResolveException(
        WindMapResolveCode.variableNotInFeed,
      );
    }

    return uri.toString();
  }
}

enum WindMapResolveCode {
  metadataFailed,
  variableNotInFeed,
}

class WindMapResolveException implements Exception {
  const WindMapResolveException(this.code, {this.statusCode});

  final WindMapResolveCode code;
  final int? statusCode;

  @override
  String toString() => code.name;
}
