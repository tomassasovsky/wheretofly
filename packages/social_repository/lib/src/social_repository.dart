import 'package:social_api_client/social_api_client.dart';

/// Social feed and profile operations.
class SocialRepository {
  SocialRepository({required SocialApiClient apiClient})
      : _apiClient = apiClient;

  final SocialApiClient _apiClient;

  Future<List<SocialPost>> feed({String? cursor}) =>
      _apiClient.fetchFeed(cursor: cursor);

  Future<SocialPost> post(String id) => _apiClient.fetchPost(id);

  Future<SocialPost> createPost({
    required String caption,
    double? locationLat,
    double? locationLon,
    Map<String, dynamic>? verdictSnapshot,
    String? zoneVersion,
    List<Map<String, dynamic>> media = const [],
  }) {
    return _apiClient.createPost(
      caption: caption,
      locationLat: locationLat,
      locationLon: locationLon,
      verdictSnapshot: verdictSnapshot,
      zoneVersion: zoneVersion,
      media: media,
    );
  }

  Future<SocialProfile> profile(String handle) =>
      _apiClient.fetchProfile(handle);

  Future<List<SocialPost>> userPosts(String handle, {String? cursor}) =>
      _apiClient.fetchUserPosts(handle, cursor: cursor);

  Future<void> follow(String handle) => _apiClient.follow(handle);

  Future<List<SocialComment>> comments(String postId) =>
      _apiClient.fetchComments(postId);

  Future<SocialComment> addComment({
    required String postId,
    required String body,
  }) =>
      _apiClient.addComment(postId: postId, body: body);

  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
  }) =>
      _apiClient.reportContent(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
      );
}
