/// Author summary on posts and comments.
class SocialAuthor {
  const SocialAuthor({
    required this.handle,
    required this.displayName,
    this.avatarUrl,
  });

  factory SocialAuthor.fromJson(Map<String, dynamic> json) {
    return SocialAuthor(
      handle: json['handle'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String handle;
  final String displayName;
  final String? avatarUrl;
}
