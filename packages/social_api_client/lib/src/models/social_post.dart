import 'package:social_api_client/src/models/post_media.dart';
import 'package:social_api_client/src/models/social_author.dart';

/// A fly-check reel/post with required photo or video media.
class SocialPost {
  const SocialPost({
    required this.id,
    required this.caption,
    required this.createdAt,
    required this.author,
    this.locationLat,
    this.locationLon,
    this.verdictSnapshot,
    this.zoneVersion,
    this.media = const [],
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final mediaRaw = json['media'];
    final media = mediaRaw is List
        ? mediaRaw
            .whereType<Map<String, dynamic>>()
            .map(PostMedia.fromJson)
            .toList()
        : const <PostMedia>[];
    return SocialPost(
      id: json['id'] as String,
      caption: json['caption'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      author: SocialAuthor.fromJson(
        (json['author'] as Map<String, dynamic>?) ?? const {},
      ),
      locationLat: (location?['lat'] as num?)?.toDouble(),
      locationLon: (location?['lon'] as num?)?.toDouble(),
      verdictSnapshot: json['verdictSnapshot'] as Map<String, dynamic>?,
      zoneVersion: json['zoneVersion'] as String?,
      media: media,
    );
  }

  final String id;
  final String caption;
  final DateTime createdAt;
  final SocialAuthor author;
  final double? locationLat;
  final double? locationLon;
  final Map<String, dynamic>? verdictSnapshot;
  final String? zoneVersion;
  final List<PostMedia> media;

  bool get hasMedia => media.isNotEmpty;

  PostMedia? get primaryMedia => media.isEmpty ? null : media.first;
}
