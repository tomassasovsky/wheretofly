import 'dart:convert';
import 'dart:math';

import 'package:backend/db/database.dart';
import 'package:backend/util/json_codec.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

/// Social posts, comments, follows, and flight logs.
class PostService {
  /// Creates a post service with optional test [uuid].
  PostService({required Database database, Uuid? uuid})
    : _db = database,
      _uuid = uuid ?? const Uuid();

  final Database _db;
  final Uuid _uuid;

  /// Creates a media post with optional location and fly-check snapshot.
  Future<Map<String, dynamic>> createPost({
    required String authorId,
    required String caption,
    double? locationLat,
    double? locationLon,
    Map<String, dynamic>? verdictSnapshot,
    String? zoneVersion,
    List<Map<String, dynamic>> media = const [],
  }) async {
    if (media.isEmpty) {
      throw PostServiceException(
        'At least one photo or video is required',
        400,
      );
    }
    final user = await _db.connection.execute(
      Sql.named('SELECT email_verified_at FROM users WHERE id = @id'),
      parameters: {'id': authorId},
    );
    if (user.isEmpty) throw PostServiceException('User not found', 404);
    if (user.first[0] == null) {
      throw PostServiceException(
        'Email verification required before posting',
        403,
      );
    }

    final postId = _uuid.v4();
    double? fuzzLat;
    double? fuzzLon;
    if (locationLat != null && locationLon != null) {
      final fuzzed = _fuzzLocation(locationLat, locationLon);
      fuzzLat = fuzzed.lat;
      fuzzLon = fuzzed.lon;
    }

    await _db.connection.execute(
      Sql.named('''
        INSERT INTO posts (
          id, author_id, caption, location_lat, location_lon,
          location_fuzz_meters, verdict_snapshot, zone_version
        ) VALUES (
          @id, @authorId, @caption, @lat, @lon, @fuzz, @verdict, @zoneVersion
        )
      '''),
      parameters: {
        'id': postId,
        'authorId': authorId,
        'caption': caption,
        'lat': fuzzLat,
        'lon': fuzzLon,
        'fuzz': fuzzLat == null ? null : 500,
        'verdict': verdictSnapshot == null ? null : jsonEncode(verdictSnapshot),
        'zoneVersion': zoneVersion,
      },
    );

    for (final item in media) {
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO post_media (id, post_id, media_type, storage_key, mime_type, size_bytes)
          VALUES (@id, @postId, @type, @key, @mime, @size)
        '''),
        parameters: {
          'id': _uuid.v4(),
          'postId': postId,
          'type': item['mediaType'],
          'key': item['storageKey'],
          'mime': item['mimeType'],
          'size': item['sizeBytes'],
        },
      );
    }

    return (await getPost(postId)) ?? {'id': postId};
  }

  /// Loads a single post by id, including attached media.
  Future<Map<String, dynamic>?> getPost(String postId) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT p.id, p.caption, p.location_lat, p.location_lon,
               p.verdict_snapshot, p.zone_version, p.created_at,
               u.handle, u.display_name, u.avatar_url
        FROM posts p
        JOIN users u ON u.id = p.author_id
        WHERE p.id = @id AND p.is_hidden = FALSE AND u.is_hidden = FALSE
      '''),
      parameters: {'id': postId},
    );
    if (result.isEmpty) return null;
    final post = _mapPostRow(result.first);
    await _attachMediaToPosts([post]);
    return post;
  }

  static const _mediaPostsFilter = '''
          AND EXISTS (
            SELECT 1 FROM post_media pm WHERE pm.post_id = p.id
          )
  ''';

  /// Returns media posts from pilots [userId] follows, newest first.
  Future<List<Map<String, dynamic>>> getFeed({
    required String userId,
    String? cursor,
    int limit = 20,
  }) async {
    const baseQuery =
        '''
        SELECT p.id, p.caption, p.location_lat, p.location_lon,
               p.verdict_snapshot, p.zone_version, p.created_at,
               u.handle, u.display_name, u.avatar_url
        FROM posts p
        JOIN users u ON u.id = p.author_id
        JOIN follows f ON f.following_id = p.author_id
        WHERE f.follower_id = @userId
          AND p.is_hidden = FALSE
          AND u.is_hidden = FALSE
          $_mediaPostsFilter
    ''';
    final Result result;
    if (cursor == null) {
      result = await _db.connection.execute(
        Sql.named('''
          $baseQuery
          ORDER BY p.created_at DESC
          LIMIT @limit
        '''),
        parameters: {'userId': userId, 'limit': limit},
      );
    } else {
      result = await _db.connection.execute(
        Sql.named('''
          $baseQuery
            AND p.created_at < @cursor::timestamptz
          ORDER BY p.created_at DESC
          LIMIT @limit
        '''),
        parameters: {
          'userId': userId,
          'cursor': cursor,
          'limit': limit,
        },
      );
    }
    final posts = result.map(_mapPostRow).toList();
    await _attachMediaToPosts(posts);
    return posts;
  }

  /// Returns media posts authored by @handle, newest first.
  Future<List<Map<String, dynamic>>> getPostsByHandle({
    required String handle,
    String? cursor,
    int limit = 20,
  }) async {
    const baseQuery =
        '''
        SELECT p.id, p.caption, p.location_lat, p.location_lon,
               p.verdict_snapshot, p.zone_version, p.created_at,
               u.handle, u.display_name, u.avatar_url
        FROM posts p
        JOIN users u ON u.id = p.author_id
        WHERE u.handle = @handle
          AND p.is_hidden = FALSE
          AND u.is_hidden = FALSE
          $_mediaPostsFilter
    ''';
    final Result result;
    if (cursor == null) {
      result = await _db.connection.execute(
        Sql.named('''
          $baseQuery
          ORDER BY p.created_at DESC
          LIMIT @limit
        '''),
        parameters: {
          'handle': handle.toLowerCase(),
          'limit': limit,
        },
      );
    } else {
      result = await _db.connection.execute(
        Sql.named('''
          $baseQuery
            AND p.created_at < @cursor::timestamptz
          ORDER BY p.created_at DESC
          LIMIT @limit
        '''),
        parameters: {
          'handle': handle.toLowerCase(),
          'cursor': cursor,
          'limit': limit,
        },
      );
    }
    final posts = result.map(_mapPostRow).toList();
    await _attachMediaToPosts(posts);
    return posts;
  }

  /// Lists comments on [postId] in chronological order.
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT c.id, c.body, c.created_at,
               u.handle, u.display_name, u.avatar_url
        FROM comments c
        JOIN users u ON u.id = c.author_id
        WHERE c.post_id = @postId AND c.is_hidden = FALSE
        ORDER BY c.created_at ASC
      '''),
      parameters: {'postId': postId},
    );
    return result
        .map(
          (row) => {
            'id': row[0],
            'body': row[1],
            'createdAt': (row[2]! as DateTime).toUtc().toIso8601String(),
            'author': {
              'handle': row[3],
              'displayName': row[4],
              'avatarUrl': row[5],
            },
          },
        )
        .toList();
  }

  /// Follows [targetId] or creates a pending request when approval is required.
  Future<void> follow({
    required String followerId,
    required String targetId,
  }) async {
    if (followerId == targetId) {
      throw PostServiceException('Cannot follow yourself', 400);
    }
    final target = await _db.connection.execute(
      Sql.named('SELECT follow_mode FROM users WHERE id = @id'),
      parameters: {'id': targetId},
    );
    if (target.isEmpty) throw PostServiceException('User not found', 404);
    final mode = target.first[0]! as String;
    if (mode == 'approval') {
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO follow_requests (id, requester_id, target_id)
          VALUES (@id, @requester, @target)
          ON CONFLICT (requester_id, target_id) DO NOTHING
        '''),
        parameters: {
          'id': _uuid.v4(),
          'requester': followerId,
          'target': targetId,
        },
      );
      return;
    }
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO follows (follower_id, following_id)
        VALUES (@follower, @target)
        ON CONFLICT DO NOTHING
      '''),
      parameters: {'follower': followerId, 'target': targetId},
    );
  }

  /// Accepts or declines a pending follow request for [targetId].
  Future<void> respondFollowRequest({
    required String targetId,
    required String requestId,
    required bool accept,
  }) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT requester_id FROM follow_requests
        WHERE id = @id AND target_id = @target AND status = 'pending'
      '''),
      parameters: {'id': requestId, 'target': targetId},
    );
    if (result.isEmpty) throw PostServiceException('Request not found', 404);
    final requesterId = result.first[0]! as String;
    await _db.connection.execute(
      Sql.named('''
        UPDATE follow_requests
        SET status = @status
        WHERE id = @id
      '''),
      parameters: {
        'id': requestId,
        'status': accept ? 'accepted' : 'declined',
      },
    );
    if (accept) {
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO follows (follower_id, following_id)
          VALUES (@follower, @target)
          ON CONFLICT DO NOTHING
        '''),
        parameters: {'follower': requesterId, 'target': targetId},
      );
    }
  }

  /// Adds a comment to [postId] and returns the created payload.
  Future<Map<String, dynamic>> addComment({
    required String postId,
    required String authorId,
    required String body,
  }) async {
    final id = _uuid.v4();
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO comments (id, post_id, author_id, body)
        VALUES (@id, @postId, @authorId, @body)
      '''),
      parameters: {
        'id': id,
        'postId': postId,
        'authorId': authorId,
        'body': body,
      },
    );
    final author = await _db.connection.execute(
      Sql.named('''
        SELECT handle, display_name, avatar_url
        FROM users WHERE id = @id
      '''),
      parameters: {'id': authorId},
    );
    final row = author.first;
    return {
      'id': id,
      'postId': postId,
      'body': body,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'author': {
        'handle': row[0],
        'displayName': row[1],
        'avatarUrl': row[2],
      },
    };
  }

  /// Persists a flight log entry with verdict and optional weather data.
  Future<Map<String, dynamic>> createFlightLog({
    required String userId,
    required double lat,
    required double lon,
    required Map<String, dynamic> verdictSnapshot,
    required DateTime startedAt,
    Map<String, dynamic>? weatherSnapshot,
    String notes = '',
    DateTime? endedAt,
  }) async {
    final id = _uuid.v4();
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO flight_logs (
          id, user_id, location_lat, location_lon, verdict_snapshot,
          weather_snapshot, notes, started_at, ended_at
        ) VALUES (
          @id, @userId, @lat, @lon, @verdict, @weather, @notes, @started, @ended
        )
      '''),
      parameters: {
        'id': id,
        'userId': userId,
        'lat': lat,
        'lon': lon,
        'verdict': jsonEncode(verdictSnapshot),
        'weather': weatherSnapshot == null ? null : jsonEncode(weatherSnapshot),
        'notes': notes,
        'started': startedAt,
        'ended': endedAt,
      },
    );
    return {'id': id};
  }

  /// Records a moderation report against a post, comment, or user.
  Future<void> reportContent({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO reports (id, reporter_id, target_type, target_id, reason)
        VALUES (@id, @reporter, @type, @target, @reason)
      '''),
      parameters: {
        'id': _uuid.v4(),
        'reporter': reporterId,
        'type': targetType,
        'target': targetId,
        'reason': reason,
      },
    );
  }

  Future<void> _attachMediaToPosts(List<Map<String, dynamic>> posts) async {
    if (posts.isEmpty) return;
    final ids = posts.map((post) => post['id'] as String).toList();
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT post_id, id, media_type, storage_key, mime_type
        FROM post_media
        WHERE post_id = ANY(@ids::uuid[])
        ORDER BY created_at ASC
      '''),
      parameters: {'ids': ids},
    );
    final mediaByPost = <String, List<Map<String, dynamic>>>{};
    for (final row in result) {
      final postId = row[0]! as String;
      mediaByPost.putIfAbsent(postId, () => []).add({
        'id': row[1],
        'mediaType': row[2],
        'url': row[3],
        'storageKey': row[3],
        'mimeType': row[4],
      });
    }
    for (final post in posts) {
      post['media'] = mediaByPost[post['id']] ?? [];
    }
  }

  Map<String, dynamic> _mapPostRow(ResultRow row) {
    final lat = row[2] as double?;
    final lon = row[3] as double?;
    return {
      'id': row[0]! as String,
      'caption': row[1]! as String,
      'location': lat == null || lon == null ? null : {'lat': lat, 'lon': lon},
      'verdictSnapshot': decodeJsonColumn(row[4]),
      'zoneVersion': row[5] as String?,
      'createdAt': (row[6]! as DateTime).toUtc().toIso8601String(),
      'author': {
        'handle': row[7]! as String,
        'displayName': row[8]! as String,
        'avatarUrl': row[9] as String?,
      },
    };
  }

  ({double lat, double lon}) _fuzzLocation(double lat, double lon) {
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final distanceMeters = random.nextDouble() * 500;
    const earthRadius = 6378137.0;
    final dLat = (distanceMeters * cos(angle)) / earthRadius;
    final dLon =
        (distanceMeters * sin(angle)) / (earthRadius * cos(lat * pi / 180));
    return (
      lat: lat + dLat * 180 / pi,
      lon: lon + dLon * 180 / pi,
    );
  }
}

/// Thrown when social/post operations fail with an HTTP status.
class PostServiceException implements Exception {
  /// Creates a post service error with [message] and [statusCode].
  PostServiceException(this.message, this.statusCode);

  /// Human-readable error returned to the client.
  final String message;

  /// Suggested HTTP status for API responses.
  final int statusCode;
}
