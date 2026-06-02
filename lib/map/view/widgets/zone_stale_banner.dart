import 'package:flutter/material.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:zones_api_client/zones_api_client.dart';

/// Non-blocking banner when live zone data may be stale.
class ZoneStaleBanner extends StatelessWidget {
  const ZoneStaleBanner({
    required this.metadata,
    super.key,
  });

  final ZoneFeedMetadata metadata;

  @override
  Widget build(BuildContext context) {
    if (metadata.isEmpty || metadata.updatedAt == null) {
      return const SizedBox.shrink();
    }

    final age = DateTime.now().difference(metadata.updatedAt!);
    if (age.inDays < 7) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          l10n.zoneFeedStale(metadata.version ?? '—'),
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}
