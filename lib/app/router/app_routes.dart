import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:where_to_fly/app/router/root_navigator_key.dart';
import 'package:where_to_fly/app/view/app_shell.dart';
import 'package:where_to_fly/auth/guards/auth_guard.dart';
import 'package:where_to_fly/auth/guards/redirect_if_authenticated_guard.dart';
import 'package:where_to_fly/auth/view/login_page.dart';
import 'package:where_to_fly/auth/view/signup_page.dart';
import 'package:where_to_fly/auth/view/splash_page.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/view/map_page.dart';
import 'package:where_to_fly/messaging/view/chat_page.dart';
import 'package:where_to_fly/resources/view/resources_page.dart';
import 'package:where_to_fly/settings/view/settings_page.dart';
import 'package:where_to_fly/social/create_post_draft.dart';
import 'package:where_to_fly/social/view/create_post_page.dart';
import 'package:where_to_fly/social/view/explore_page.dart';
import 'package:where_to_fly/social/view/feed_page.dart';
import 'package:where_to_fly/social/view/me_tab_page.dart';
import 'package:where_to_fly/social/view/messages_page.dart';
import 'package:where_to_fly/social/view/post_detail_page.dart';
import 'package:where_to_fly/social/view/profile_page.dart';

part 'app_routes.g.dart';

@TypedGoRoute<SplashRoute>(
  path: '/splash',
  name: 'splash',
)
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SplashPage();
  }
}

@TypedStatefulShellRoute<AppShellRoute>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<FeedTabRoute>(path: '/feed'),
      ],
    ),
    TypedStatefulShellBranch(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ExploreTabRoute>(path: '/explore'),
      ],
    ),
    TypedStatefulShellBranch(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<MapTabRoute>(path: '/map'),
      ],
    ),
    TypedStatefulShellBranch(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<MessagesTabRoute>(path: '/messages'),
      ],
    ),
    TypedStatefulShellBranch(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<MeTabRoute>(path: '/me'),
      ],
    ),
  ],
)
class AppShellRoute extends StatefulShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return AppShell(navigationShell: navigationShell);
  }
}

class FeedTabRoute extends GoRouteData with $FeedTabRoute, GuardedRoute {
  const FeedTabRoute();

  @override
  RouteGuard get guard => const AuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FeedPage();
  }
}

class ExploreTabRoute extends GoRouteData with $ExploreTabRoute, GuardedRoute {
  const ExploreTabRoute();

  @override
  RouteGuard get guard => const AuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ExplorePage();
  }
}

class MapTabRoute extends GoRouteData with $MapTabRoute {
  const MapTabRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MapPage();
  }
}

class MessagesTabRoute extends GoRouteData
    with $MessagesTabRoute, GuardedRoute {
  const MessagesTabRoute();

  @override
  RouteGuard get guard => const AuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MessagesPage();
  }
}

class MeTabRoute extends GoRouteData with $MeTabRoute, GuardedRoute {
  const MeTabRoute();

  @override
  RouteGuard get guard => const AuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MeTabPage();
  }
}

@TypedGoRoute<SettingsRoute>(
  path: '/settings',
  name: 'settings',
)
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsPage();
  }
}

@TypedGoRoute<ResourcesRoute>(
  path: '/resources',
  name: 'resources',
)
class ResourcesRoute extends GoRouteData with $ResourcesRoute {
  const ResourcesRoute({this.highlight});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String? highlight;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ResourcesPage(
      highlightPermission:
          highlight == null ? null : PermissionLevel.fromId(highlight),
    );
  }
}

@TypedGoRoute<LoginRoute>(
  path: '/auth/login',
  name: 'login',
)
class LoginRoute extends GoRouteData with $LoginRoute, GuardedRoute {
  const LoginRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  RouteGuard get guard => const RedirectIfAuthenticatedGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginPage();
  }
}

@TypedGoRoute<SignUpRoute>(
  path: '/auth/signup',
  name: 'signup',
)
class SignUpRoute extends GoRouteData with $SignUpRoute, GuardedRoute {
  const SignUpRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  RouteGuard get guard => const RedirectIfAuthenticatedGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SignUpPage();
  }
}

@TypedGoRoute<ProfileRoute>(
  path: '/profile/:handle',
  name: 'profile',
)
class ProfileRoute extends GoRouteData with $ProfileRoute, GuardedRoute {
  const ProfileRoute({required this.handle});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String handle;

  @override
  RouteGuard get guard => const AuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ProfilePage(handle: handle);
  }
}

@TypedGoRoute<ThreadRoute>(
  path: '/threads/:threadId',
  name: 'thread',
)
class ThreadRoute extends GoRouteData with $ThreadRoute, GuardedRoute {
  const ThreadRoute({required this.threadId, this.$extra});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String threadId;
  final String? $extra;

  @override
  RouteGuard get guard => const AuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ChatPage(
      threadId: threadId,
      title: $extra ?? '',
    );
  }
}

@TypedGoRoute<CreatePostRoute>(
  path: '/posts/new',
  name: 'createPost',
)
class CreatePostRoute extends GoRouteData with $CreatePostRoute, GuardedRoute {
  const CreatePostRoute({this.$extra});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final CreatePostDraft? $extra;

  @override
  RouteGuard get guard => const AuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final draft = $extra;
    if (draft == null) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        body: Center(child: Text(l10n.socialFlyCheckMissing)),
      );
    }
    return CreatePostPage(draft: draft);
  }
}

@TypedGoRoute<PostRoute>(
  path: '/posts/:postId',
  name: 'post',
)
class PostRoute extends GoRouteData with $PostRoute, GuardedRoute {
  const PostRoute({required this.postId});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String postId;

  @override
  RouteGuard get guard => const AuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PostDetailPage(postId: postId);
  }
}
