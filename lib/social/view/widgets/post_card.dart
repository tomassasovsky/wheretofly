import 'package:flutter/material.dart';
import 'package:social_repository/social_repository.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/social/verdict_snapshot.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    super.key,
  });

  final SocialPost post;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // Surface-specific chip color. The token vocabulary and labels are shared via
  // [VerdictSnapshot]; only the palette differs between the feed and reels.
  Color _verdictColor(BuildContext context, String? verdict) {
    return switch (verdict) {
      'allowed' => const Color(0xFF2E7D32),
      'conditional' || 'allowedWithPermission' => const Color(0xFFF9A825),
      'blocked' || 'notAllowed' => const Color(0xFFD32F2F),
      'uncertain' => const Color(0xFF607D8B),
      _ => Theme.of(context).colorScheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final verdict = VerdictSnapshot.token(post.verdictSnapshot);

    return InkWell(
      onTap: () => PostRoute(postId: post.id).push<void>(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => ProfileRoute(handle: post.author.handle)
                      .push<void>(context),
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      _initials(post.author.displayName),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => ProfileRoute(handle: post.author.handle)
                        .push<void>(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '@${post.author.handle}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                ),
              ],
            ),
            if (verdict != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      _verdictColor(context, verdict).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _verdictColor(context, verdict).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flight_takeoff,
                      size: 16,
                      color: _verdictColor(context, verdict),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        VerdictSnapshot.label(l10n, verdict),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _verdictColor(context, verdict),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (post.caption.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(post.caption),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () =>
                      PostRoute(postId: post.id).push<void>(context),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () =>
                      PostRoute(postId: post.id).push<void>(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
