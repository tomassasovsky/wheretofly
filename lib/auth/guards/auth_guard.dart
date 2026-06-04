import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/app/router/root_navigator_key.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';

/// Requires an authenticated session; redirects guests to login with
/// [returnToQueryKey].
class AuthGuard extends RouteGuard {
  const AuthGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    final authContext = _authContext(context);
    if (authContext == null) {
      resolver.redirect(const SplashRoute().location);
    } else {
      final authState = authContext.read<AuthCubit>().state;
      if (authState.status == AuthStatus.unknown) {
        resolver.redirect(const SplashRoute().location);
      } else if (!authState.isAuthenticated) {
        final returnTo = state.uri.path;
        resolver.redirect(
          Uri(
            path: const LoginRoute().location,
            queryParameters: {returnToQueryKey: returnTo},
          ).toString(),
        );
      } else {
        resolver.next();
      }
    }
  }

  BuildContext? _authContext(BuildContext context) {
    try {
      context.read<AuthCubit>();
      return context;
    } on Object {
      return rootNavigatorKey.currentContext;
    }
  }
}
