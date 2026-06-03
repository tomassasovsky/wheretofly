import 'package:flutter/material.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/app/view/app_shell.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';

/// Discover pilots, permits, and map shortcuts.
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _handleController = TextEditingController();

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  void _openProfile() {
    final handle = _handleController.text.trim().replaceAll('@', '');
    if (handle.isEmpty) return;
    ProfileRoute(handle: handle).push<void>(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navExplore),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _handleController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _openProfile(),
            decoration: InputDecoration(
              hintText: l10n.exploreSearchHint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.exploreShortcuts, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _ExploreTile(
            icon: Icons.assignment_outlined,
            title: l10n.permissionsAndResources,
            subtitle: l10n.exploreResourcesSubtitle,
            onTap: () => const ResourcesRoute().push<void>(context),
          ),
          _ExploreTile(
            icon: Icons.map_outlined,
            title: l10n.navMap,
            subtitle: l10n.exploreMapSubtitle,
            onTap: () => AppShellTab.goTo(context, AppShellTab.map),
          ),
        ],
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
