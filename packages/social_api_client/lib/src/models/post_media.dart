/// Photo or video attached to a fly-check post.
enum PostMediaType { photo, video }

class PostMedia {
  const PostMedia({
    required this.id,
    required this.type,
    required this.url,
    this.mimeType,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['mediaType'] as String? ?? 'photo';
    return PostMedia(
      id: json['id'] as String,
      type: typeRaw == 'video' ? PostMediaType.video : PostMediaType.photo,
      url: json['url'] as String? ?? json['storageKey'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
    );
  }

  final String id;
  final PostMediaType type;
  final String url;
  final String? mimeType;

  bool get isVideo => type == PostMediaType.video;
}
