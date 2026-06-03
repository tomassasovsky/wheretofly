import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/social/view/profile_page.dart';

/// Profile tab — own profile when signed in, account hub otherwise.
class MeTabPage extends StatelessWidget {
  const MeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final handle = authState.session?.handle;
        if (authState.isAuthenticated && handle != null) {
          return ProfilePage(handle: handle, isOwnProfile: true);
        }
        return const _AccountHub();
      },
    );
  }
}

class _AccountHub extends StatelessWidget {
  const _AccountHub();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navProfile),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => const SettingsRoute().push<void>(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.profileSignInPrompt, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => openLogin(context),
                child: Text(l10n.authLogIn),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => openSignUp(context),
                child: Text(l10n.authSignUpPrompt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
