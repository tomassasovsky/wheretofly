import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:weather_api_client/src/models/weather_alert_subscription.dart';
import 'package:weather_api_client/src/models/weather_snapshot.dart';

class WeatherApiException implements Exception {
  const WeatherApiException(this.message, {this.statusCode = 400});
  final String message;
  final int statusCode;
}

/// Data client for backend weather proxy.
class WeatherApiClient {
  WeatherApiClient({
    required this.baseUrl,
    required this.accessTokenProvider,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final Uri baseUrl;
  final Future<String?> Function() accessTokenProvider;
  final http.Client _http;

  Future<WeatherSnapshot> fetch({
    required double lat,
    required double lon,
  }) async {
    final token = await accessTokenProvider();
    if (token == null) {
      throw const WeatherApiException('Not authenticated', statusCode: 401);
    }
    final uri = baseUrl.replace(
      path: '/v1/weather',
      queryParameters: {
        'lat': lat.toStringAsFixed(4),
        'lon': lon.toStringAsFixed(4),
      },
    );
    http.Response response;
    try {
      response = await _http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const WeatherApiException('Network timeout', statusCode: 408);
    }
    if (response.statusCode >= 400) {
      throw WeatherApiException(
        'Weather request failed',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const WeatherApiException('Invalid response');
    }
    return WeatherSnapshot.fromJson(decoded);
  }

  Future<List<WeatherAlertSubscription>> listAlertSubscriptions() async {
    final token = await accessTokenProvider();
    if (token == null) {
      throw const WeatherApiException('Not authenticated', statusCode: 401);
    }
    final uri = baseUrl.replace(path: '/v1/weather/alerts');
    final response = await _http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      throw WeatherApiException(
        'Alert list failed',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final items = decoded['subscriptions'] as List? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(WeatherAlertSubscription.fromJson)
        .toList();
  }

  Future<WeatherAlertSubscription> createAlertSubscription({
    required String label,
    required double lat,
    required double lon,
    double windThresholdMs = 8,
  }) async {
    final token = await accessTokenProvider();
    if (token == null) {
      throw const WeatherApiException('Not authenticated', statusCode: 401);
    }
    final uri = baseUrl.replace(path: '/v1/weather/alerts');
    final response = await _http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'label': label,
        'lat': lat,
        'lon': lon,
        'windThresholdMs': windThresholdMs,
      }),
    );
    if (response.statusCode >= 400) {
      throw WeatherApiException(
        'Alert create failed',
        statusCode: response.statusCode,
      );
    }
    return WeatherAlertSubscription.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteAlertSubscription(String id) async {
    final token = await accessTokenProvider();
    if (token == null) {
      throw const WeatherApiException('Not authenticated', statusCode: 401);
    }
    final uri = baseUrl.replace(path: '/v1/weather/alerts/$id');
    final response = await _http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      throw WeatherApiException(
        'Alert delete failed',
        statusCode: response.statusCode,
      );
    }
  }
}
