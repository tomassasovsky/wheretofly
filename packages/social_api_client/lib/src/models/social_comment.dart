import 'package:social_api_client/src/models/social_author.dart';

/// Comment on a post.
class SocialComment {
  const SocialComment({
    required this.id,
    required this.postId,
    required this.body,
    required this.createdAt,
    required this.author,
  });

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    return SocialComment(
      id: json['id'] as String,
      postId: json['postId'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      author: SocialAuthor.fromJson(
        (json['author'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  final String id;
  final String postId;
  final String body;
  final DateTime createdAt;
  final SocialAuthor author;
}
