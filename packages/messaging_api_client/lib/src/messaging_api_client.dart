import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:messaging_api_client/src/models/chat_message.dart';
import 'package:messaging_api_client/src/models/chat_thread.dart';
import 'package:messaging_api_client/src/models/notification_preferences.dart';

class MessagingApiException implements Exception {
  const MessagingApiException(this.message, {this.statusCode = 400});

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

/// Data client for threads, messages, and notification settings.
class MessagingApiClient {
  MessagingApiClient({
    required this.baseUrl,
    required this.accessTokenProvider,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final Uri baseUrl;
  final Future<String?> Function() accessTokenProvider;
  final http.Client _http;

  Future<List<ChatThread>> fetchThreads() async {
    final decoded = await _get('/v1/messages');
    final threads = decoded['threads'];
    if (threads is! List) return [];
    return threads
        .whereType<Map<String, dynamic>>()
        .map(ChatThread.fromJson)
        .toList();
  }

  Future<ChatThread> createDirectThread({required String userId}) async {
    final decoded = await _post('/v1/messages', {'userId': userId});
    return ChatThread(id: decoded['id'] as String, isGroup: false);
  }

  Future<List<ChatMessage>> fetchMessages(String threadId) async {
    final decoded = await _get('/v1/messages/$threadId');
    final messages = decoded['messages'];
    if (messages is! List) return [];
    return messages
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => ChatMessage.fromJson({
            ...json,
            'threadId': threadId,
          }),
        )
        .toList();
  }

  Future<ChatMessage> sendMessage({
    required String threadId,
    required String body,
  }) async {
    final decoded = await _post('/v1/messages/$threadId', {'body': body});
    return ChatMessage.fromJson({
      ...decoded,
      'threadId': threadId,
    });
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _post('/v1/notifications/device_tokens', {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterDeviceToken({required String token}) async {
    await _delete('/v1/notifications/device_tokens', {'token': token});
  }

  Future<NotificationPreferences> fetchNotificationPreferences() async {
    final decoded = await _get('/v1/notifications/preferences');
    return NotificationPreferences.fromJson(decoded);
  }

  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async {
    final decoded = await _patch(
      '/v1/notifications/preferences',
      prefs.toJson(),
    );
    return NotificationPreferences.fromJson(decoded);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await accessTokenProvider();
    if (token == null) {
      throw const MessagingApiException('Not authenticated', statusCode: 401);
    }
    final uri = baseUrl.replace(path: path);
    final response = await _http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await accessTokenProvider();
    if (token == null) {
      throw const MessagingApiException('Not authenticated', statusCode: 401);
    }
    final uri = baseUrl.replace(path: path);
    final response = await _http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await accessTokenProvider();
    if (token == null) {
      throw const MessagingApiException('Not authenticated', statusCode: 401);
    }
    final uri = baseUrl.replace(path: path);
    final response = await _http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<void> _delete(String path, Map<String, dynamic> body) async {
    final token = await accessTokenProvider();
    if (token == null) {
      throw const MessagingApiException('Not authenticated', statusCode: 401);
    }
    final uri = baseUrl.replace(path: path);
    final response = await _http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(body),
    );
    _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      final message =
          response.body.isEmpty ? 'Request failed' : response.body.trim();
      throw MessagingApiException(message, statusCode: response.statusCode);
    }
    if (response.statusCode >= 400) {
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'Request failed';
      throw MessagingApiException(message, statusCode: response.statusCode);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const MessagingApiException('Invalid response');
    }
    return decoded;
  }
}
