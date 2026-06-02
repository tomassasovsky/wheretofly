import 'dart:convert';

import 'package:backend/config/app_config.dart';
import 'package:backend/util/json_codec.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

enum WeatherAdvisoryLevel { good, caution, highCaution, notRecommended }

/// Weather snapshot returned by the API proxy.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.lat,
    required this.lon,
    required this.fetchedAt,
    required this.current,
    required this.hourly,
    required this.alerts,
    required this.advisory,
  });

  final double lat;
  final double lon;
  final DateTime fetchedAt;
  final Map<String, dynamic> current;
  final List<Map<String, dynamic>> hourly;
  final List<Map<String, dynamic>> alerts;
  final Map<String, dynamic> advisory;

  Map<String, dynamic> toJson() => {
    'location': {'lat': lat, 'lon': lon},
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'current': current,
    'hourly': hourly,
    'alerts': alerts,
    'advisory': advisory,
  };
}

/// Proxies OpenWeather One Call 3.0 and SMN CAP alerts with advisory scoring.
class WeatherService {
  WeatherService({
    required AppConfig config,
    http.Client? httpClient,
  }) : _config = config,
       _http = httpClient ?? http.Client();

  final AppConfig _config;
  final http.Client _http;
  final _cache = <String, _CacheEntry>{};

  static const _smnCapUrl =
      'http://www.smn.gov.ar/feeds/CAP/avisocortoplazo/rss_acpCAP.xml';

  Future<WeatherSnapshot> getWeather({
    required double lat,
    required double lon,
  }) async {
    final cacheKey = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    final cached = _cache[cacheKey];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.snapshot;
    }

    if (_config.openWeatherApiKey.isEmpty) {
      return _mockWeather(lat: lat, lon: lon);
    }

    final uri = Uri.https('api.openweathermap.org', '/data/3.0/onecall', {
      'lat': '$lat',
      'lon': '$lon',
      'units': 'metric',
      'lang': 'es',
      'exclude': 'minutely',
      'appid': _config.openWeatherApiKey,
    });
    final response = await _http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw WeatherServiceException(
        'Weather upstream error ${response.statusCode}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final current = (body['current'] as Map?)?.cast<String, dynamic>() ?? {};
    final hourly = decodeJsonMapList(body['hourly'], take: 24);
    var alerts = decodeJsonMapList(body['alerts']);
    alerts = [...alerts, ...await _fetchSmnAlerts()];

    final advisory = _scoreAdvisory(current: current, alerts: alerts);
    final snapshot = WeatherSnapshot(
      lat: lat,
      lon: lon,
      fetchedAt: DateTime.now(),
      current: current,
      hourly: hourly,
      alerts: alerts,
      advisory: advisory,
    );
    _cache[cacheKey] = _CacheEntry(
      snapshot: snapshot,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
    return snapshot;
  }

  Map<String, dynamic> _scoreAdvisory({
    required Map<String, dynamic> current,
    required List<Map<String, dynamic>> alerts,
  }) {
    if (alerts.isNotEmpty) {
      return {
        'level': WeatherAdvisoryLevel.notRecommended.name,
        'reasons': ['Alerta meteorológica activa (SMN)'],
      };
    }
    final wind = (current['wind_speed'] as num?)?.toDouble() ?? 0;
    final gust = (current['wind_gust'] as num?)?.toDouble() ?? wind;
    final reasons = <String>[];
    WeatherAdvisoryLevel level;
    if (wind > 10.7 || gust > 12) {
      level = WeatherAdvisoryLevel.notRecommended;
      reasons.add(
        'Viento ${wind.toStringAsFixed(1)} m/s, ráfagas ${gust.toStringAsFixed(1)} m/s',
      );
    } else if (wind > 8 || gust > 10) {
      level = WeatherAdvisoryLevel.highCaution;
      reasons.add('Viento elevado para drones ligeros');
    } else if (wind > 5 || gust > 7) {
      level = WeatherAdvisoryLevel.caution;
      reasons.add('Precaución por viento moderado');
    } else {
      level = WeatherAdvisoryLevel.good;
      reasons.add('Condiciones favorables');
    }
    return {'level': level.name, 'reasons': reasons};
  }

  Future<List<Map<String, dynamic>>> _fetchSmnAlerts() async {
    try {
      final response = await _http
          .get(Uri.parse(_smnCapUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      final document = XmlDocument.parse(response.body);
      return document.findAllElements('item').map((item) {
        final title = item.getElement('title')?.innerText ?? 'Alerta SMN';
        final description = item.getElement('description')?.innerText ?? '';
        return {
          'source': 'SMN',
          'event': title,
          'description': description,
        };
      }).toList();
    } on Object {
      return [];
    }
  }

  WeatherSnapshot _mockWeather({required double lat, required double lon}) {
    final current = {
      'wind_speed': 3.5,
      'wind_gust': 5.0,
      'wind_deg': 180,
      'humidity': 55,
      'visibility': 10000,
    };
    return WeatherSnapshot(
      lat: lat,
      lon: lon,
      fetchedAt: DateTime.now(),
      current: current,
      hourly: const [],
      alerts: const [],
      advisory: _scoreAdvisory(current: current, alerts: const []),
    );
  }
}

class WeatherServiceException implements Exception {
  WeatherServiceException(this.message);
  final String message;
}

class _CacheEntry {
  _CacheEntry({required this.snapshot, required this.expiresAt});
  final WeatherSnapshot snapshot;
  final DateTime expiresAt;
}
