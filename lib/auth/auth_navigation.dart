import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/app/view/app_shell.dart';

const _returnToQueryKey = 'returnTo';

const _shellTabPaths = {
  '/feed',
  '/explore',
  '/map',
  '/messages',
  '/me',
};

/// Resolves the main tab the user should return to after authentication.
String loginReturnDestination(BuildContext context) {
  final shell = StatefulNavigationShell.maybeOf(context);
  if (shell != null) {
    return switch (shell.currentIndex) {
      AppShellTab.feed => const FeedTabRoute().location,
      AppShellTab.explore => const ExploreTabRoute().location,
      AppShellTab.map => const MapTabRoute().location,
      AppShellTab.messages => const MessagesTabRoute().location,
      AppShellTab.profile => const MeTabRoute().location,
      _ => const MapTabRoute().location,
    };
  }

  final path = GoRouter.of(context).state.uri.path;
  if (_shellTabPaths.contains(path)) return path;

  return const MapTabRoute().location;
}

/// Opens login and remembers the active shell tab for post-auth navigation.
void openLogin(BuildContext context) {
  final router = GoRouter.of(context);
  final currentPath = router.state.uri.path;
  final returnTo = router.state.uri.queryParameters[_returnToQueryKey] ??
      loginReturnDestination(context);
  final loginLocation = Uri(
    path: '/auth/login',
    queryParameters: {_returnToQueryKey: returnTo},
  ).toString();

  if (currentPath.startsWith('/auth/')) {
    router.pushReplacement(loginLocation);
    return;
  }
  router.push(loginLocation);
}

/// Opens sign-up, preserving any login returnTo query parameter.
void openSignUp(BuildContext context) {
  final router = GoRouter.of(context);
  final returnTo = router.state.uri.queryParameters[_returnToQueryKey];
  final from = returnTo ?? loginReturnDestination(context);
  router.pushReplacement(
    Uri(
      path: '/auth/signup',
      queryParameters: {_returnToQueryKey: from},
    ).toString(),
  );
}

String authReturnDestination(GoRouter router) {
  final returnTo = router.state.uri.queryParameters[_returnToQueryKey];
  if (returnTo != null && _shellTabPaths.contains(returnTo)) {
    return returnTo;
  }
  return const MapTabRoute().location;
}

/// Navigates away from auth screens after a successful sign-in or sign-up.
///
/// Prefer [GoRouter.pop] so the shell (map, feed videos) stays mounted.
/// Fall back to [GoRouter.go] only when login was opened without a back stack
/// or a single pop did not leave the auth flow (legacy stacked auth routes).
void navigateAfterAuthentication(BuildContext context) {
  final router = GoRouter.of(context);
  final fallback = authReturnDestination(router);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!router.state.uri.path.startsWith('/auth/')) return;

    if (router.canPop()) {
      router.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (router.state.uri.path.startsWith('/auth/')) {
          router.go(fallback);
        }
      });
      return;
    }

    router.go(fallback);
  });
}
