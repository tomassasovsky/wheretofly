/// Public user profile.
class SocialProfile {
  const SocialProfile({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.bio,
    required this.followMode,
    required this.createdAt,
    this.avatarUrl,
  });

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    return SocialProfile(
      id: json['id'] as String,
      handle: json['handle'] as String,
      displayName: json['displayName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      followMode: json['followMode'] as String? ?? 'open',
      createdAt: DateTime.parse(json['createdAt'] as String),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String id;
  final String handle;
  final String displayName;
  final String bio;
  final String followMode;
  final DateTime createdAt;
  final String? avatarUrl;

  bool get requiresApprovalToFollow => followMode == 'approval';
}
