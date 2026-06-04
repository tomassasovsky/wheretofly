import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/l10n/localized_labels.dart';
import 'package:where_to_fly/resources/view/permit_resources.dart';
import 'package:where_to_fly/theme/app_snack_bar.dart';

/// Screen listing how to obtain each permission level, with links to the
/// official ANAC / government resources to request them.
class ResourcesPage extends StatefulWidget {
  const ResourcesPage({this.highlightPermission, super.key});

  /// When set, scrolls to and visually highlights the matching guide card.
  final PermissionLevel? highlightPermission;

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  late final Map<PermissionLevel, GlobalKey> _guideKeys;

  @override
  void initState() {
    super.initState();
    _guideKeys = {
      for (final level in PermissionLevel.values) level: GlobalKey(),
    };

    final highlight = widget.highlightPermission;
    if (highlight != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _guideKeys[highlight]?.currentContext;
        if (context == null || !context.mounted) return;
        final reduce = MediaQuery.of(context).disableAnimations;
        Scrollable.ensureVisible(
          context,
          duration: reduce ? Duration.zero : const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final highlight = widget.highlightPermission;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resourcesTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l10n.resourcesIntro),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    const FlightDataSourcesRoute().push<void>(context),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(l10n.flightDataSourcesResourcesLink),
              ),
            ),
            const SizedBox(height: 4),
            for (final guide in buildPermitGuides(l10n))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _GuideCard(
                  key: _guideKeys[guide.level],
                  guide: guide,
                  highlighted: highlight == guide.level,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.guide,
    required this.highlighted,
    super.key,
  });

  final PermitGuide guide;
  final bool highlighted;

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      context.showAppSnackBar(
        AppLocalizations.of(context).couldNotOpen(url),
        intent: AppSnackBarIntent.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: highlighted ? colorScheme.primaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlighted ? colorScheme.primary : colorScheme.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlighted) ...[
              Row(
                children: [
                  Icon(Icons.bookmark, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.recommendedPermitGuide,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              guide.level.l10nLabel(l10n),
              style: theme.textTheme.titleMedium,
            ),
            Text(
              guide.level.l10nCategory(l10n),
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Text(guide.summary, style: theme.textTheme.bodyMedium),
            const Divider(height: 24),
            for (final resource in guide.resources)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ExcludeSemantics(
                  child: Icon(
                    resource.url != null
                        ? Icons.open_in_new
                        : Icons.info_outline,
                  ),
                ),
                title: Text(resource.title),
                subtitle: Text(resource.description),
                onTap: resource.url == null
                    ? null
                    : () => _open(context, resource.url!),
              ),
          ],
        ),
      ),
    );
  }
}
