import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:social_api_client/src/models/social_comment.dart';
import 'package:social_api_client/src/models/social_post.dart';
import 'package:social_api_client/src/models/social_profile.dart';

class SocialApiException implements Exception {
  const SocialApiException(this.message, {this.statusCode = 400});
  final String message;
  final int statusCode;
}

/// Data client for posts, profiles, and follows.
class SocialApiClient {
  SocialApiClient({
    required this.baseUrl,
    required this.accessTokenProvider,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final Uri baseUrl;
  final Future<String?> Function() accessTokenProvider;
  final http.Client _http;

  Future<List<SocialPost>> fetchFeed({String? cursor}) async {
    final decoded = await _get(
      '/v1/posts',
      query: cursor == null ? null : {'cursor': cursor},
    );
    return _parsePosts(decoded['posts']);
  }

  Future<SocialPost> fetchPost(String id) async {
    final decoded = await _get('/v1/posts/$id');
    return SocialPost.fromJson(decoded);
  }

  Future<SocialPost> createPost({
    required String caption,
    double? locationLat,
    double? locationLon,
    Map<String, dynamic>? verdictSnapshot,
    String? zoneVersion,
    List<Map<String, dynamic>> media = const [],
  }) async {
    final decoded = await _post('/v1/posts', {
      'caption': caption,
      if (locationLat != null) 'locationLat': locationLat,
      if (locationLon != null) 'locationLon': locationLon,
      if (verdictSnapshot != null) 'verdictSnapshot': verdictSnapshot,
      if (zoneVersion != null) 'zoneVersion': zoneVersion,
      if (media.isNotEmpty) 'media': media,
    });
    return SocialPost.fromJson(decoded);
  }

  Future<SocialProfile> fetchProfile(String handle) async {
    final decoded = await _get('/v1/users/$handle');
    return SocialProfile.fromJson(decoded);
  }

  Future<List<SocialPost>> fetchUserPosts(
    String handle, {
    String? cursor,
  }) async {
    final decoded = await _get(
      '/v1/users/$handle/posts',
      query: cursor == null ? null : {'cursor': cursor},
    );
    return _parsePosts(decoded['posts']);
  }

  Future<void> follow(String handle) async {
    await _post('/v1/users/$handle/follow', {});
  }

  Future<List<SocialComment>> fetchComments(String postId) async {
    final decoded = await _get('/v1/posts/$postId/comments');
    final comments = decoded['comments'];
    if (comments is! List) return [];
    return comments
        .whereType<Map<String, dynamic>>()
        .map((json) => SocialComment.fromJson({...json, 'postId': postId}))
        .toList();
  }

  Future<SocialComment> addComment({
    required String postId,
    required String body,
  }) async {
    final decoded = await _post('/v1/posts/$postId/comments', {'body': body});
    return SocialComment.fromJson({...decoded, 'postId': postId});
  }

  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    await _post('/v1/reports', {
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
    });
  }

  List<SocialPost> _parsePosts(Object? posts) {
    if (posts is! List) return [];
    return posts
        .whereType<Map<String, dynamic>>()
        .map(SocialPost.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
  }) async {
    final token = await accessTokenProvider();
    if (token == null) {
      throw const SocialApiException('Not authenticated', statusCode: 401);
    }
    final uri = baseUrl.replace(path: path, queryParameters: query);
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
      throw const SocialApiException('Not authenticated', statusCode: 401);
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

  Map<String, dynamic> _decode(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      final message =
          response.body.isEmpty ? 'Request failed' : response.body.trim();
      throw SocialApiException(message, statusCode: response.statusCode);
    }
    if (response.statusCode >= 400) {
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'Request failed';
      throw SocialApiException(message, statusCode: response.statusCode);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const SocialApiException('Invalid response');
    }
    return decoded;
  }
}
