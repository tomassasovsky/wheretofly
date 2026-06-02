/// Weather advisory level from the backend proxy.
enum WeatherAdvisoryLevel {
  good,
  caution,
  highCaution,
  notRecommended;

  static WeatherAdvisoryLevel fromString(String value) {
    return WeatherAdvisoryLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => WeatherAdvisoryLevel.caution,
    );
  }
}

/// Normalized weather snapshot from the backend.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.lat,
    required this.lon,
    required this.fetchedAt,
    required this.current,
    required this.hourly,
    required this.alerts,
    required this.advisoryLevel,
    required this.advisoryReasons,
  });

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    final advisory = json['advisory'] as Map<String, dynamic>? ?? {};
    final location = json['location'] as Map<String, dynamic>? ?? {};
    return WeatherSnapshot(
      lat: (location['lat'] as num?)?.toDouble() ?? 0,
      lon: (location['lon'] as num?)?.toDouble() ?? 0,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      current: (json['current'] as Map?)?.cast<String, dynamic>() ?? {},
      hourly: (json['hourly'] as List?)
              ?.whereType<Map<dynamic, dynamic>>()
              .map((e) => e.cast<String, dynamic>())
              .toList() ??
          const [],
      alerts: (json['alerts'] as List?)
              ?.whereType<Map<dynamic, dynamic>>()
              .map((e) => e.cast<String, dynamic>())
              .toList() ??
          const [],
      advisoryLevel: WeatherAdvisoryLevel.fromString(
        advisory['level'] as String? ?? 'caution',
      ),
      advisoryReasons:
          (advisory['reasons'] as List?)?.whereType<String>().toList() ??
              const [],
    );
  }

  final double lat;
  final double lon;
  final DateTime fetchedAt;
  final Map<String, dynamic> current;
  final List<Map<String, dynamic>> hourly;
  final List<Map<String, dynamic>> alerts;
  final WeatherAdvisoryLevel advisoryLevel;
  final List<String> advisoryReasons;

  double? get windSpeedMs => (current['wind_speed'] as num?)?.toDouble();
  double? get windGustMs => (current['wind_gust'] as num?)?.toDouble();
  int? get windDirectionDeg => (current['wind_deg'] as num?)?.toInt();
}
