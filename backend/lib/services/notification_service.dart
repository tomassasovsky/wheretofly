import 'package:backend/db/database.dart';
import 'package:backend/util/json_codec.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

/// Device token registration and notification dispatch (FCM stub for v1).
class NotificationService {
  /// Creates a notification service with optional test [uuid].
  NotificationService({required Database database, Uuid? uuid})
    : _db = database,
      _uuid = uuid ?? const Uuid();

  final Database _db;
  final Uuid _uuid;

  /// Stores or updates a push [token] for [userId] on [platform].
  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final normalized = normalizeDevicePlatform(platform);
    if (normalized == null) {
      throw NotificationException('Invalid platform: $platform', 400);
    }
    final exists = await _db.connection.execute(
      Sql.named('''
        SELECT 1 FROM users
        WHERE id = @userId AND is_hidden = FALSE
        LIMIT 1
      '''),
      parameters: {'userId': userId},
    );
    if (exists.isEmpty) {
      throw NotificationException('Unauthorized', 401);
    }
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO device_tokens (id, user_id, token, platform)
        VALUES (@id, @userId, @token, @platform)
        ON CONFLICT (user_id, token) DO NOTHING
      '''),
      parameters: {
        'id': _uuid.v4(),
        'userId': userId,
        'token': token,
        'platform': normalized,
      },
    );
  }

  /// Removes a registered device [token] for [userId].
  Future<void> unregisterDeviceToken({
    required String userId,
    required String token,
  }) async {
    await _db.connection.execute(
      Sql.named('''
        DELETE FROM device_tokens
        WHERE user_id = @userId AND token = @token
      '''),
      parameters: {'userId': userId, 'token': token},
    );
  }

  /// Returns all registered push tokens for [userId].
  Future<List<String>> tokensForUser(String userId) async {
    final result = await _db.connection.execute(
      Sql.named('SELECT token FROM device_tokens WHERE user_id = @userId'),
      parameters: {'userId': userId},
    );
    return result.map((row) => row[0]! as String).toList();
  }

  /// Sends a push notification via FCM when configured.
  /// Logs payload in dev when FCM credentials are absent.
  Future<void> sendToUser({
    required String userId,
    required String category,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final prefs = await _db.connection.execute(
      Sql.named('''
        SELECT notification_follows, notification_messages,
               notification_comments, notification_weather
        FROM users WHERE id = @userId
      '''),
      parameters: {'userId': userId},
    );
    if (prefs.isEmpty) return;
    final enabled = switch (category) {
      'follow' => prefs.first[0]! as bool,
      'message' => prefs.first[1]! as bool,
      'comment' => prefs.first[2]! as bool,
      'weather' => prefs.first[3]! as bool,
      _ => true,
    };
    if (!enabled) return;

    final tokens = await tokensForUser(userId);
    if (tokens.isEmpty) return;

    // FCM HTTP v1 integration point — requires service account JSON on server.
    // ignore: avoid_print
    print('Push [$category] to ${tokens.length} device(s): $title — $body');
  }

  /// Reads notification category toggles for [userId].
  Future<Map<String, bool>> getNotificationPreferences(String userId) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT notification_follows, notification_messages,
               notification_comments, notification_weather
        FROM users WHERE id = @userId
      '''),
      parameters: {'userId': userId},
    );
    if (result.isEmpty) {
      return const {
        'follows': true,
        'messages': true,
        'comments': true,
        'weather': true,
      };
    }
    final row = result.first;
    return {
      'follows': row[0]! as bool,
      'messages': row[1]! as bool,
      'comments': row[2]! as bool,
      'weather': row[3]! as bool,
    };
  }

  /// Updates one or more notification toggles and returns the new state.
  Future<Map<String, bool>> updateNotificationPreferences({
    required String userId,
    bool? follows,
    bool? messages,
    bool? comments,
    bool? weather,
  }) async {
    await _db.connection.execute(
      Sql.named('''
        UPDATE users SET
          notification_follows = COALESCE(@follows, notification_follows),
          notification_messages = COALESCE(@messages, notification_messages),
          notification_comments = COALESCE(@comments, notification_comments),
          notification_weather = COALESCE(@weather, notification_weather),
          updated_at = NOW()
        WHERE id = @userId
      '''),
      parameters: {
        'userId': userId,
        'follows': follows,
        'messages': messages,
        'comments': comments,
        'weather': weather,
      },
    );
    return getNotificationPreferences(userId);
  }
}

/// Thrown when notification operations fail with an HTTP status.
class NotificationException implements Exception {
  /// Creates a notification error with [message] and [statusCode].
  NotificationException(this.message, this.statusCode);

  /// Human-readable error returned to the client.
  final String message;

  /// Suggested HTTP status for API responses.
  final int statusCode;
}
