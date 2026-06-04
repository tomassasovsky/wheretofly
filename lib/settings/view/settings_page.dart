import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:where_to_fly/app/app_mode.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/messaging/cubit/notification_preferences_cubit.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';
import 'package:where_to_fly/theme/app_snack_bar.dart';
import 'package:where_to_fly/weather/weather_alerts_cubit.dart';

/// Full-screen settings: appearance, language, and map data credits.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const sponsorUrl = 'https://cafecito.app/aquilesdev';
  static const websiteUrl = 'https://aquiles.dev';
  static const githubUrl = 'https://github.com/tomassasovsky';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !context.mounted) return;
        if (context.canPop()) {
          context.pop();
          return;
        }
        if (AppMode.mapOnly) {
          const MapTabRoute().go(context);
        } else {
          const MeTabRoute().go(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final cubit = context.read<SettingsCubit>();
            final currentLang = state.locale?.languageCode;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.theme, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l10n.themeSystem),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l10n.themeLight),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l10n.themeDark),
                            ),
                          ],
                          selected: {state.themeMode},
                          onSelectionChanged: (s) =>
                              cubit.setThemeMode(s.first),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.language, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      _ChoiceTile(
                        label: l10n.languageSystem,
                        selected: currentLang == null,
                        onTap: () => cubit.setLanguage(null),
                      ),
                      _ChoiceTile(
                        label: l10n.languageSpanish,
                        selected: currentLang == 'es',
                        onTap: () => cubit.setLanguage('es'),
                      ),
                      _ChoiceTile(
                        label: l10n.languageEnglish,
                        selected: currentLang == 'en',
                        onTap: () => cubit.setLanguage('en'),
                      ),
                    ],
                  ),
                ),
                if (!AppMode.mapOnly) ...[
                  const SizedBox(height: 12),
                  _AccountSection(l10n: l10n),
                ],
                const SizedBox(height: 12),
                _SettingsCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.menu_book_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(l10n.permissionsAndResources),
                        subtitle: Text(
                          l10n.exploreResourcesSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => const ResourcesRoute().push<void>(context),
                      ),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.article_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(l10n.attributions),
                        subtitle: Text(
                          l10n.attributionsSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            const AttributionsRoute().push<void>(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _openSponsorLink(context),
                    icon: const Icon(Icons.local_cafe_outlined, size: 20),
                    label: Text(l10n.sponsorMe),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.sponsorMeDescription,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _CreditsFooter(l10n: l10n),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openSponsorLink(BuildContext context) async {
    final uri = Uri.parse(sponsorUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      context.showAppSnackBar(
        AppLocalizations.of(context).couldNotOpen(sponsorUrl),
        intent: AppSnackBarIntent.error,
      );
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _CreditsFooter extends StatelessWidget {
  const _CreditsFooter({required this.l10n});

  final AppLocalizations l10n;

  Future<void> _openLink(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
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

    return Column(
      children: [
        Text(
          l10n.creditsDevelopedBy,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => _openLink(context, SettingsPage.websiteUrl),
              icon: const Icon(Icons.language_outlined, size: 18),
              label: Text(l10n.creditsWebsite),
            ),
            TextButton.icon(
              onPressed: () => _openLink(context, SettingsPage.githubUrl),
              icon: const Icon(Icons.code, size: 18),
              label: Text(l10n.creditsGithub),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check, color: theme.colorScheme.primary, size: 22)
          : null,
      onTap: onTap,
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return Column(
          children: [
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.authAccount,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  if (authState.isAuthenticated)
                    OutlinedButton(
                      onPressed: () => context.read<AuthCubit>().logout(),
                      child: Text(l10n.authLogOut),
                    )
                  else
                    FilledButton(
                      onPressed: () => openLogin(context),
                      child: Text(l10n.authLogIn),
                    ),
                ],
              ),
            ),
            if (authState.isAuthenticated) ...[
              const SizedBox(height: 12),
              _WeatherAlertsCard(l10n: l10n),
              const SizedBox(height: 12),
              _NotificationPrefsCard(l10n: l10n),
            ],
          ],
        );
      },
    );
  }
}

class _WeatherAlertsCard extends StatelessWidget {
  const _WeatherAlertsCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<WeatherAlertsCubit, WeatherAlertsState>(
      builder: (context, alertsState) {
        return _SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.weatherAlertsTitle,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (alertsState.subscriptions.isEmpty)
                Text(
                  l10n.weatherAlertEmpty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...alertsState.subscriptions.map(
                  (sub) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(sub.label),
                    subtitle: Text(
                      l10n.weatherAlertWindThreshold(
                        sub.windThresholdMs.toStringAsFixed(0),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          context.read<WeatherAlertsCubit>().remove(sub.id),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationPrefsCard extends StatelessWidget {
  const _NotificationPrefsCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<NotificationPreferencesCubit,
        NotificationPreferencesState>(
      builder: (context, prefsState) {
        if (prefsState.status == NotificationPreferencesStatus.initial) {
          return const SizedBox.shrink();
        }
        final cubit = context.read<NotificationPreferencesCubit>();
        final prefs = prefsState.preferences;
        final loading =
            prefsState.status == NotificationPreferencesStatus.loading;

        return _SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.notificationPrefsTitle,
                style: theme.textTheme.titleSmall,
              ),
              if (prefsState.status == NotificationPreferencesStatus.error)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    prefsState.errorMessage == 'notification_prefs_load_failed'
                        ? l10n.notificationPrefsLoadFailed
                        : (prefsState.errorMessage ??
                            l10n.notificationPrefsLoadFailed),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.notificationPrefsFollows),
                value: prefs.follows,
                onChanged: loading
                    ? null
                    : (value) => cubit.update(prefs.copyWith(follows: value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.notificationPrefsMessages),
                value: prefs.messages,
                onChanged: loading
                    ? null
                    : (value) => cubit.update(prefs.copyWith(messages: value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.notificationPrefsComments),
                value: prefs.comments,
                onChanged: loading
                    ? null
                    : (value) => cubit.update(prefs.copyWith(comments: value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.notificationPrefsWeather),
                value: prefs.weather,
                onChanged: loading
                    ? null
                    : (value) => cubit.update(prefs.copyWith(weather: value)),
              ),
            ],
          ),
        );
      },
    );
  }
}
