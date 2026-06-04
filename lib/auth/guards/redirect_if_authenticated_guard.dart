import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:where_to_fly/app/router/root_navigator_key.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';

/// Redirects authenticated users away from login/sign-up screens.
class RedirectIfAuthenticatedGuard extends RouteGuard {
  const RedirectIfAuthenticatedGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    final authContext = _authContext(context);
    if (authContext != null &&
        authContext.read<AuthCubit>().state.isAuthenticated) {
      resolver.redirect(resolveAuthReturnPath(state.uri));
    } else {
      resolver.next();
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
