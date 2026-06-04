import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// Drone flight advisory level derived from wind and SMN alerts.
enum WeatherAdvisoryLevel {
  /// Conditions are favorable for flight.
  good,

  /// Moderate wind — exercise caution.
  caution,

  /// Elevated wind — high caution advised.
  highCaution,

  /// Active alerts or strong wind — not recommended.
  notRecommended,
}

/// Weather snapshot returned by the API proxy.
class WeatherSnapshot {
  /// Creates an immutable weather payload for API responses.
  const WeatherSnapshot({
    required this.lat,
    required this.lon,
    required this.fetchedAt,
    required this.current,
    required this.hourly,
    required this.alerts,
    required this.advisory,
  });

  /// Query latitude in decimal degrees.
  final double lat;

  /// Query longitude in decimal degrees.
  final double lon;

  /// Timestamp when upstream data was fetched.
  final DateTime fetchedAt;

  /// Current conditions (wind in m/s, compatible with the Flutter client).
  final Map<String, dynamic> current;

  /// Hourly forecast entries (up to 24).
  final List<Map<String, dynamic>> hourly;

  /// Active SMN alert payloads.
  final List<Map<String, dynamic>> alerts;

  /// Computed advisory level and machine-readable reason codes.
  ///
  /// Reason codes are localized client-side (e.g. `windHigh`, `favorable`).
  final Map<String, dynamic> advisory;

  /// Serializes the snapshot for JSON API responses.
  Map<String, dynamic> toJson() => {
    'location': {'lat': lat, 'lon': lon},
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'current': current,
    'hourly': hourly,
    'alerts': alerts,
    'advisory': advisory,
  };
}

/// Proxies Open-Meteo forecast data and SMN CAP alerts with advisory scoring.
class WeatherService {
  /// Creates a weather proxy with optional HTTP client for tests.
  WeatherService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;
  final _cache = <String, _CacheEntry>{};

  static const _openMeteoHost = 'api.open-meteo.com';
  static const _smnCapUrl =
      'http://www.smn.gov.ar/feeds/CAP/avisocortoplazo/rss_acpCAP.xml';

  /// Fetches (or returns cached) weather for [lat]/[lon].
  Future<WeatherSnapshot> getWeather({
    required double lat,
    required double lon,
  }) async {
    final cacheKey = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    final cached = _cache[cacheKey];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.snapshot;
    }

    final uri = Uri.https(_openMeteoHost, '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lon',
      'current':
          'wind_speed_10m,wind_gusts_10m,wind_direction_10m,'
          'relative_humidity_2m',
      'hourly': 'wind_speed_10m,wind_gusts_10m,wind_direction_10m',
      'wind_speed_unit': 'ms',
      'forecast_days': '2',
      'timezone': 'auto',
    });
    final response = await _http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw WeatherServiceException(
        'Weather upstream error ${response.statusCode}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final current = _mapCurrent(body['current']);
    final hourly = _mapHourly(body['hourly'] as Map<String, dynamic>?);
    final alerts = await _fetchSmnAlerts();

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

  Map<String, dynamic> _mapCurrent(Object? raw) {
    final block = (raw as Map?)?.cast<String, dynamic>() ?? {};
    return {
      'wind_speed': (block['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      'wind_gust': (block['wind_gusts_10m'] as num?)?.toDouble() ?? 0,
      'wind_deg': (block['wind_direction_10m'] as num?)?.toDouble() ?? 0,
      'humidity': (block['relative_humidity_2m'] as num?)?.toDouble() ?? 0,
    };
  }

  List<Map<String, dynamic>> _mapHourly(Map<String, dynamic>? hourly) {
    if (hourly == null) return const [];

    final times = hourly['time'];
    if (times is! List || times.isEmpty) return const [];

    final windSpeed = hourly['wind_speed_10m'];
    final windGust = hourly['wind_gusts_10m'];
    final windDir = hourly['wind_direction_10m'];
    final count = times.length < 24 ? times.length : 24;
    final entries = <Map<String, dynamic>>[];

    for (var i = 0; i < count; i++) {
      entries.add({
        'dt': _epochSeconds(times[i]),
        'wind_speed': _listValue(windSpeed, i),
        'wind_gust': _listValue(windGust, i),
        'wind_deg': _listValue(windDir, i),
      });
    }
    return entries;
  }

  static double _listValue(Object? list, int index) {
    if (list is List && index < list.length) {
      return (list[index] as num?)?.toDouble() ?? 0;
    }
    return 0;
  }

  static int _epochSeconds(Object? time) {
    if (time is String) {
      return DateTime.parse(time).millisecondsSinceEpoch ~/ 1000;
    }
    return 0;
  }

  Map<String, dynamic> _scoreAdvisory({
    required Map<String, dynamic> current,
    required List<Map<String, dynamic>> alerts,
  }) {
    if (alerts.isNotEmpty) {
      return {
        'level': WeatherAdvisoryLevel.notRecommended.name,
        'reasons': ['smnAlert'],
      };
    }
    final wind = (current['wind_speed'] as num?)?.toDouble() ?? 0;
    final gust = (current['wind_gust'] as num?)?.toDouble() ?? wind;
    final reasons = <String>[];
    WeatherAdvisoryLevel level;
    if (wind > 10.7 || gust > 12) {
      level = WeatherAdvisoryLevel.notRecommended;
      reasons.add('windHigh');
    } else if (wind > 8 || gust > 10) {
      level = WeatherAdvisoryLevel.highCaution;
      reasons.add('windElevated');
    } else if (wind > 5 || gust > 7) {
      level = WeatherAdvisoryLevel.caution;
      reasons.add('windModerate');
    } else {
      level = WeatherAdvisoryLevel.good;
      reasons.add('favorable');
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
}

/// Thrown when the weather upstream fails or returns an error.
class WeatherServiceException implements Exception {
  /// Creates an exception with a diagnostic [message].
  WeatherServiceException(this.message);

  /// Human-readable failure description.
  final String message;
}

class _CacheEntry {
  _CacheEntry({required this.snapshot, required this.expiresAt});
  final WeatherSnapshot snapshot;
  final DateTime expiresAt;
}
