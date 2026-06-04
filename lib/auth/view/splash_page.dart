import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_to_fly/app/app_mode.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';

/// Bootstrap screen shown while the initial session check runs.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status == AuthStatus.unknown &&
          current.status != AuthStatus.unknown,
      listener: (context, state) {
        if (state.isAuthenticated) {
          const MapTabRoute().replace(context);
        } else if (state.status == AuthStatus.unauthenticated) {
          if (AppMode.mapOnly ||
              const bool.fromEnvironment('AUTH_LAND_ON_MAP')) {
            const MapTabRoute().replace(context);
          } else {
            const LoginRoute().replace(context);
          }
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.splashLoading,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
