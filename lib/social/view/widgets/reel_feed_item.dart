import 'package:flutter/material.dart';
import 'package:social_api_client/social_api_client.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/social/view/widgets/post_media_view.dart';

/// TikTok-style full-screen reel with media, caption overlay, and actions.
class ReelFeedItem extends StatelessWidget {
  const ReelFeedItem({
    required this.post,
    required this.isActive,
    super.key,
  });

  final SocialPost post;
  final bool isActive;

  Color _verdictColor(String? verdict) {
    return switch (verdict) {
      'allowed' => const Color(0xFF66BB6A),
      'allowedWithPermission' => const Color(0xFFFFCA28),
      'notAllowed' => const Color(0xFFEF5350),
      _ => Colors.white,
    };
  }

  String _verdictLabel(AppLocalizations l10n, String? verdict) {
    return switch (verdict) {
      'allowed' => l10n.verdictAllowed,
      'allowedWithPermission' => l10n.verdictAllowedWithPermission,
      'notAllowed' => l10n.verdictNotAllowed,
      _ => l10n.socialShareFlyCheck,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = post.primaryMedia;
    if (media == null) return const SizedBox.shrink();

    final verdict = post.verdictSnapshot?['verdict']?.toString();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!media.isVideo) PostMediaView(media: media, isActive: isActive),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.75),
              ],
              stops: const [0, 0.35, 1],
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 88 + bottomInset,
          child: Column(
            children: [
              _SideAction(
                icon: Icons.chat_bubble_outline,
                onTap: () => PostRoute(postId: post.id).push<void>(context),
              ),
              const SizedBox(height: 18),
              _SideAction(
                icon: Icons.share_outlined,
                onTap: () => PostRoute(postId: post.id).push<void>(context),
              ),
              const SizedBox(height: 18),
              _SideAction(
                icon: Icons.flight_takeoff,
                onTap: () => PostRoute(postId: post.id).push<void>(context),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 72,
          bottom: 24 + bottomInset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => ProfileRoute(handle: post.author.handle)
                    .push<void>(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Text(
                        post.author.displayName.isNotEmpty
                            ? post.author.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '@${post.author.handle}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (verdict != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _verdictColor(verdict).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _verdictColor(verdict).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    _verdictLabel(l10n, verdict),
                    style: TextStyle(
                      color: _verdictColor(verdict),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              if (post.caption.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  post.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (media.isVideo)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 56,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'REEL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
