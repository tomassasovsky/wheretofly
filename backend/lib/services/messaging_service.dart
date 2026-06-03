import 'package:backend/db/database.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

/// Direct and group messaging.
class MessagingService {
  /// Creates a messaging service with optional test [uuid].
  MessagingService({required Database database, Uuid? uuid})
    : _db = database,
      _uuid = uuid ?? const Uuid();

  final Database _db;
  final Uuid _uuid;

  /// Opens or reuses a 1:1 thread between [userId] and [otherUserId].
  Future<Map<String, dynamic>> createDirectThread({
    required String userId,
    required String otherUserId,
  }) async {
    final existing = await _findDirectThread(userId, otherUserId);
    if (existing != null) return {'id': existing};

    final threadId = _uuid.v4();
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO threads (id, is_group, created_by)
        VALUES (@id, FALSE, @creator)
      '''),
      parameters: {'id': threadId, 'creator': userId},
    );
    for (final member in [userId, otherUserId]) {
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO thread_members (thread_id, user_id, role)
          VALUES (@threadId, @userId, 'member')
        '''),
        parameters: {'threadId': threadId, 'userId': member},
      );
    }
    return {'id': threadId};
  }

  /// Creates a named group thread with [memberIds] plus [creatorId].
  Future<Map<String, dynamic>> createGroup({
    required String creatorId,
    required String name,
    required List<String> memberIds,
  }) async {
    final threadId = _uuid.v4();
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO threads (id, is_group, name, created_by)
        VALUES (@id, TRUE, @name, @creator)
      '''),
      parameters: {'id': threadId, 'name': name, 'creator': creatorId},
    );
    final members = {...memberIds, creatorId};
    for (final member in members) {
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO thread_members (thread_id, user_id, role)
          VALUES (@threadId, @userId, @role)
        '''),
        parameters: {
          'threadId': threadId,
          'userId': member,
          'role': member == creatorId ? 'admin' : 'member',
        },
      );
    }
    return {'id': threadId, 'name': name};
  }

  /// Appends a message to [threadId] on behalf of [senderId].
  Future<Map<String, dynamic>> sendMessage({
    required String threadId,
    required String senderId,
    required String body,
    String? mediaKey,
  }) async {
    await _assertMembership(threadId: threadId, userId: senderId);
    final messageId = _uuid.v4();
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO messages (id, thread_id, sender_id, body, media_key)
        VALUES (@id, @threadId, @senderId, @body, @mediaKey)
      '''),
      parameters: {
        'id': messageId,
        'threadId': threadId,
        'senderId': senderId,
        'body': body,
        'mediaKey': mediaKey,
      },
    );
    return {
      'id': messageId,
      'threadId': threadId,
      'senderId': senderId,
      'body': body,
      'mediaKey': mediaKey,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Lists messages in [threadId] for [userId], optionally after [cursor].
  Future<List<Map<String, dynamic>>> listMessages({
    required String threadId,
    required String userId,
    String? cursor,
    int limit = 50,
  }) async {
    await _assertMembership(threadId: threadId, userId: userId);
    final Result result;
    if (cursor == null) {
      result = await _db.connection.execute(
        Sql.named('''
          SELECT id, sender_id, body, media_key, created_at
          FROM messages
          WHERE thread_id = @threadId
          ORDER BY created_at ASC
          LIMIT @limit
        '''),
        parameters: {'threadId': threadId, 'limit': limit},
      );
    } else {
      result = await _db.connection.execute(
        Sql.named('''
          SELECT id, sender_id, body, media_key, created_at
          FROM messages
          WHERE thread_id = @threadId
            AND created_at > @cursor::timestamptz
          ORDER BY created_at ASC
          LIMIT @limit
        '''),
        parameters: {
          'threadId': threadId,
          'cursor': cursor,
          'limit': limit,
        },
      );
    }
    return result
        .map(
          (row) => {
            'id': row[0],
            'senderId': row[1],
            'body': row[2],
            'mediaKey': row[3],
            'createdAt': (row[4]! as DateTime).toUtc().toIso8601String(),
          },
        )
        .toList();
  }

  /// Returns inbox summaries for all threads [userId] belongs to.
  Future<List<Map<String, dynamic>>> listThreads({
    required String userId,
  }) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT
          t.id,
          t.is_group,
          t.name,
          lm.body,
          lm.created_at,
          ou.handle,
          ou.display_name
        FROM threads t
        JOIN thread_members me ON me.thread_id = t.id AND me.user_id = @userId
        LEFT JOIN LATERAL (
          SELECT body, created_at
          FROM messages
          WHERE thread_id = t.id
          ORDER BY created_at DESC
          LIMIT 1
        ) lm ON TRUE
        LEFT JOIN thread_members other
          ON other.thread_id = t.id
         AND other.user_id <> @userId
         AND t.is_group = FALSE
        LEFT JOIN users ou ON ou.id = other.user_id
        ORDER BY COALESCE(lm.created_at, t.created_at) DESC
      '''),
      parameters: {'userId': userId},
    );
    return result
        .map(
          (row) => {
            'id': row[0],
            'isGroup': row[1],
            'name': row[2],
            'lastMessageBody': row[3],
            'lastMessageAt': row[4] == null
                ? null
                : (row[4]! as DateTime).toUtc().toIso8601String(),
            'otherHandle': row[5],
            'otherDisplayName': row[6],
          },
        )
        .toList();
  }

  /// Returns member ids in [threadId] excluding [userId].
  Future<List<String>> otherMemberIds({
    required String threadId,
    required String userId,
  }) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT user_id FROM thread_members
        WHERE thread_id = @threadId AND user_id <> @userId
      '''),
      parameters: {'threadId': threadId, 'userId': userId},
    );
    return result.map((row) => row[0]! as String).toList();
  }

  Future<void> _assertMembership({
    required String threadId,
    required String userId,
  }) async {
    final membership = await _db.connection.execute(
      Sql.named('''
        SELECT 1 FROM thread_members
        WHERE thread_id = @threadId AND user_id = @userId
      '''),
      parameters: {'threadId': threadId, 'userId': userId},
    );
    if (membership.isEmpty) {
      throw MessagingException('Not a member of this thread', 403);
    }
  }

  Future<String?> _findDirectThread(String a, String b) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT t.id
        FROM threads t
        JOIN thread_members m1 ON m1.thread_id = t.id AND m1.user_id = @a
        JOIN thread_members m2 ON m2.thread_id = t.id AND m2.user_id = @b
        WHERE t.is_group = FALSE
        LIMIT 1
      '''),
      parameters: {'a': a, 'b': b},
    );
    return result.isEmpty ? null : result.first[0]! as String;
  }
}

/// Thrown when messaging operations fail with an HTTP status.
class MessagingException implements Exception {
  /// Creates a messaging error with [message] and [statusCode].
  MessagingException(this.message, this.statusCode);

  /// Human-readable error returned to the client.
  final String message;

  /// Suggested HTTP status for API responses.
  final int statusCode;
}
