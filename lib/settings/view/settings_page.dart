import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/messaging/cubit/notification_preferences_cubit.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';
import 'package:where_to_fly/weather/weather_alerts_cubit.dart';

/// Full-screen settings: appearance, language, and a link to support the app.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const sponsorUrl = 'https://cafecito.app/aquilesdev';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && context.mounted) {
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(l10n.theme, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
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
                  onSelectionChanged: (s) => cubit.setThemeMode(s.first),
                ),
                const SizedBox(height: 28),
                Text(l10n.language, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                _LangTile(
                  label: l10n.languageSystem,
                  selected: currentLang == null,
                  onTap: () => cubit.setLanguage(null),
                ),
                _LangTile(
                  label: l10n.languageSpanish,
                  selected: currentLang == 'es',
                  onTap: () => cubit.setLanguage('es'),
                ),
                _LangTile(
                  label: l10n.languageEnglish,
                  selected: currentLang == 'en',
                  onTap: () => cubit.setLanguage('en'),
                ),
                const SizedBox(height: 32),
                Text(l10n.authAccount, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    if (authState.isAuthenticated) {
                      return OutlinedButton(
                        onPressed: () => context.read<AuthCubit>().logout(),
                        child: Text(l10n.authLogOut),
                      );
                    }
                    return FilledButton(
                      onPressed: () => openLogin(context),
                      child: Text(l10n.authLogIn),
                    );
                  },
                ),
                const SizedBox(height: 32),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    if (!authState.isAuthenticated) {
                      return const SizedBox.shrink();
                    }
                    return BlocBuilder<WeatherAlertsCubit, WeatherAlertsState>(
                      builder: (context, alertsState) {
                        return Column(
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
                                  title: Text(sub.label),
                                  subtitle: Text(
                                    l10n.weatherAlertWindThreshold(
                                      sub.windThresholdMs.toStringAsFixed(0),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => context
                                        .read<WeatherAlertsCubit>()
                                        .remove(sub.id),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 32),
                          ],
                        );
                      },
                    );
                  },
                ),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    if (!authState.isAuthenticated) {
                      return const SizedBox.shrink();
                    }
                    return BlocBuilder<NotificationPreferencesCubit,
                        NotificationPreferencesState>(
                      builder: (context, prefsState) {
                        if (prefsState.status ==
                            NotificationPreferencesStatus.initial) {
                          return const SizedBox.shrink();
                        }
                        final cubit =
                            context.read<NotificationPreferencesCubit>();
                        final prefs = prefsState.preferences;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.notificationPrefsTitle,
                              style: theme.textTheme.titleSmall,
                            ),
                            if (prefsState.status ==
                                NotificationPreferencesStatus.error)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  prefsState.errorMessage ==
                                          'notification_prefs_load_failed'
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
                              onChanged: prefsState.status ==
                                      NotificationPreferencesStatus.loading
                                  ? null
                                  : (value) => cubit.update(
                                        prefs.copyWith(follows: value),
                                      ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.notificationPrefsMessages),
                              value: prefs.messages,
                              onChanged: prefsState.status ==
                                      NotificationPreferencesStatus.loading
                                  ? null
                                  : (value) => cubit.update(
                                        prefs.copyWith(messages: value),
                                      ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.notificationPrefsComments),
                              value: prefs.comments,
                              onChanged: prefsState.status ==
                                      NotificationPreferencesStatus.loading
                                  ? null
                                  : (value) => cubit.update(
                                        prefs.copyWith(comments: value),
                                      ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.notificationPrefsWeather),
                              value: prefs.weather,
                              onChanged: prefsState.status ==
                                      NotificationPreferencesStatus.loading
                                  ? null
                                  : (value) => cubit.update(
                                        prefs.copyWith(weather: value),
                                      ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        );
                      },
                    );
                  },
                ),
                const Divider(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _openSponsorLink(context),
                  icon: const Icon(Icons.local_cafe_outlined),
                  label: Text(l10n.sponsorMe),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.sponsorMeDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).couldNotOpen(sponsorUrl)),
        ),
      );
    }
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? color : null,
      ),
      title: Text(label),
    );
  }
}
