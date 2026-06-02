import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:where_to_fly/app/view/app_shell.dart';
import 'package:where_to_fly/auth/view/login_page.dart';
import 'package:where_to_fly/auth/view/signup_page.dart';
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

@TypedGoRoute<FeedTabRoute>(
  path: '/feed',
  name: 'feed',
)
class FeedTabRoute extends GoRouteData with $FeedTabRoute, GuardedRoute {
  const FeedTabRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FeedPage();
  }
}

@TypedGoRoute<ExploreTabRoute>(
  path: '/explore',
  name: 'explore',
)
class ExploreTabRoute extends GoRouteData with $ExploreTabRoute, GuardedRoute {
  const ExploreTabRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ExplorePage();
  }
}

@TypedGoRoute<MapTabRoute>(
  path: '/map',
  name: 'map',
)
class MapTabRoute extends GoRouteData with $MapTabRoute, GuardedRoute {
  const MapTabRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MapPage();
  }
}

@TypedGoRoute<MessagesTabRoute>(
  path: '/messages',
  name: 'messages',
)
class MessagesTabRoute extends GoRouteData
    with $MessagesTabRoute, GuardedRoute {
  const MessagesTabRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MessagesPage();
  }
}

@TypedGoRoute<MeTabRoute>(
  path: '/me',
  name: 'me',
)
class MeTabRoute extends GoRouteData with $MeTabRoute, GuardedRoute {
  const MeTabRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MeTabPage();
  }
}

@TypedGoRoute<SettingsRoute>(
  path: '/settings',
  name: 'settings',
)
class SettingsRoute extends GoRouteData with $SettingsRoute, GuardedRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsPage();
  }
}

@TypedGoRoute<ResourcesRoute>(
  path: '/resources',
  name: 'resources',
)
class ResourcesRoute extends GoRouteData with $ResourcesRoute, GuardedRoute {
  const ResourcesRoute({this.highlight});

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

  final String handle;

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

  final String threadId;
  final String? $extra;

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

  final CreatePostDraft? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final draft = $extra;
    if (draft == null) {
      return const Scaffold(
        body: Center(child: Text('Missing fly-check data')),
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

  final String postId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PostDetailPage(postId: postId);
  }
}
