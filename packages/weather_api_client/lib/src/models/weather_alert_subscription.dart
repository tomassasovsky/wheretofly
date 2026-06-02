/// Saved weather alert location from the backend.
class WeatherAlertSubscription {
  const WeatherAlertSubscription({
    required this.id,
    required this.label,
    required this.lat,
    required this.lon,
    required this.windThresholdMs,
    this.lastAlertAt,
  });

  factory WeatherAlertSubscription.fromJson(Map<String, dynamic> json) {
    return WeatherAlertSubscription(
      id: json['id'] as String,
      label: json['label'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      windThresholdMs: (json['windThresholdMs'] as num?)?.toDouble() ?? 8,
      lastAlertAt: json['lastAlertAt'] == null
          ? null
          : DateTime.parse(json['lastAlertAt'] as String),
    );
  }

  final String id;
  final String label;
  final double lat;
  final double lon;
  final double windThresholdMs;
  final DateTime? lastAlertAt;
}
