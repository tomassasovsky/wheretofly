import 'package:backend/db/database.dart';
import 'package:backend/services/notification_service.dart';
import 'package:backend/services/weather_service.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

/// Manages saved weather alert locations and evaluates thresholds.
class WeatherAlertService {
  /// Creates a weather alert service with injected dependencies.
  WeatherAlertService({
    required Database database,
    required WeatherService weatherService,
    required NotificationService notificationService,
    Uuid? uuid,
  }) : _db = database,
       _weather = weatherService,
       _notifications = notificationService,
       _uuid = uuid ?? const Uuid();

  final Database _db;
  final WeatherService _weather;
  final NotificationService _notifications;
  final Uuid _uuid;

  /// Saves a wind-threshold alert at [lat]/[lon] with a human [label].
  Future<Map<String, dynamic>> createSubscription({
    required String userId,
    required String label,
    required double lat,
    required double lon,
    double windThresholdMs = 8,
  }) async {
    final id = _uuid.v4();
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO weather_alert_subscriptions (
          id, user_id, label, lat, lon, wind_threshold_ms
        ) VALUES (
          @id, @userId, @label, @lat, @lon, @threshold
        )
      '''),
      parameters: {
        'id': id,
        'userId': userId,
        'label': label,
        'lat': lat,
        'lon': lon,
        'threshold': windThresholdMs,
      },
    );
    return {'id': id, 'label': label, 'lat': lat, 'lon': lon};
  }

  /// Returns all alert subscriptions owned by [userId].
  Future<List<Map<String, dynamic>>> listSubscriptions(String userId) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT id, label, lat, lon, wind_threshold_ms, last_alert_at
        FROM weather_alert_subscriptions
        WHERE user_id = @userId
        ORDER BY created_at DESC
      '''),
      parameters: {'userId': userId},
    );
    return result
        .map(
          (row) => {
            'id': row[0],
            'label': row[1],
            'lat': row[2],
            'lon': row[3],
            'windThresholdMs': row[4],
            'lastAlertAt': (row[5] as DateTime?)?.toUtc().toIso8601String(),
          },
        )
        .toList();
  }

  /// Removes [subscriptionId] when owned by [userId].
  Future<void> deleteSubscription({
    required String userId,
    required String subscriptionId,
  }) async {
    await _db.connection.execute(
      Sql.named('''
        DELETE FROM weather_alert_subscriptions
        WHERE id = @id AND user_id = @userId
      '''),
      parameters: {'id': subscriptionId, 'userId': userId},
    );
  }

  /// Evaluates all subscriptions and sends push notifications when needed.
  Future<int> runAlertWorker({
    Duration cooldown = const Duration(hours: 3),
  }) async {
    final subscriptions = await _db.connection.execute('''
      SELECT id, user_id, label, lat, lon, wind_threshold_ms, last_alert_at
      FROM weather_alert_subscriptions
    ''');
    var sent = 0;
    for (final row in subscriptions) {
      final id = row[0]! as String;
      final userId = row[1]! as String;
      final label = row[2]! as String;
      final lat = row[3]! as double;
      final lon = row[4]! as double;
      final threshold = row[5]! as double;
      final lastAlert = row[6] as DateTime?;
      if (lastAlert != null &&
          DateTime.now().difference(lastAlert) < cooldown) {
        continue;
      }

      final snapshot = await _weather.getWeather(lat: lat, lon: lon);
      final wind = snapshot.current['wind_speed'] as num? ?? 0;
      final gust = snapshot.current['wind_gust'] as num? ?? wind;
      final alerts = snapshot.alerts;
      final advisory = snapshot.advisory['level'] as String? ?? 'good';
      final shouldAlert =
          alerts.isNotEmpty ||
          wind >= threshold ||
          gust >= threshold + 2 ||
          advisory == 'notRecommended';
      if (!shouldAlert) continue;

      await _notifications.sendToUser(
        userId: userId,
        category: 'weather',
        title: 'Alerta meteorológica',
        body: '$label: viento ${wind.toStringAsFixed(1)} m/s',
        data: {'lat': '$lat', 'lon': '$lon'},
      );
      await _db.connection.execute(
        Sql.named('''
          UPDATE weather_alert_subscriptions
          SET last_alert_at = NOW()
          WHERE id = @id
        '''),
        parameters: {'id': id},
      );
      sent++;
    }
    return sent;
  }
}
