import 'package:flutter/material.dart';
import 'package:social_repository/social_repository.dart';
import 'package:where_to_fly/app/router/app_routes.dart';

/// Instagram-style 3-column grid of post thumbnails.
class ProfileMediaGrid extends StatelessWidget {
  const ProfileMediaGrid({required this.posts, super.key});

  final List<SocialPost> posts;

  @override
  Widget build(BuildContext context) {
    final mediaPosts = posts.where((post) => post.hasMedia).toList();
    if (mediaPosts.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: mediaPosts.length,
      itemBuilder: (context, index) {
        final post = mediaPosts[index];
        final media = post.primaryMedia!;
        return GestureDetector(
          onTap: () => PostRoute(postId: post.id).push<void>(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (media.isVideo)
                ColoredBox(
                  color: Colors.grey.shade900,
                  child: Image.network(
                    media.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Colors.black26,
                    ),
                  ),
                )
              else
                Image.network(
                  media.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              if (media.isVideo)
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child:
                        Icon(Icons.play_arrow, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
