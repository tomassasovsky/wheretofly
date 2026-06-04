// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
      $splashRoute,
      $appShellRoute,
      $settingsRoute,
      $flightDataSourcesRoute,
      $attributionsRoute,
      $resourcesRoute,
      $loginRoute,
      $signUpRoute,
      $profileRoute,
      $threadRoute,
      $createPostRoute,
      $postRoute,
    ];

RouteBase get $splashRoute => GoRouteData.$route(
      path: '/splash',
      name: 'splash',
      parentNavigatorKey: SplashRoute.$parentNavigatorKey,
      factory: $SplashRoute._fromState,
    );

mixin $SplashRoute on GoRouteData {
  static SplashRoute _fromState(GoRouterState state) => const SplashRoute();

  @override
  String get location => GoRouteData.$location(
        '/splash',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $appShellRoute => StatefulShellRouteData.$route(
      factory: $AppShellRouteExtension._fromState,
      branches: [
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/feed',
              factory: $FeedTabRoute._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/explore',
              factory: $ExploreTabRoute._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/map',
              factory: $MapTabRoute._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/messages',
              factory: $MessagesTabRoute._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/me',
              factory: $MeTabRoute._fromState,
            ),
          ],
        ),
      ],
    );

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $FeedTabRoute on GoRouteData {
  static FeedTabRoute _fromState(GoRouterState state) => const FeedTabRoute();

  @override
  String get location => GoRouteData.$location(
        '/feed',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ExploreTabRoute on GoRouteData {
  static ExploreTabRoute _fromState(GoRouterState state) =>
      const ExploreTabRoute();

  @override
  String get location => GoRouteData.$location(
        '/explore',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MapTabRoute on GoRouteData {
  static MapTabRoute _fromState(GoRouterState state) => const MapTabRoute();

  @override
  String get location => GoRouteData.$location(
        '/map',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MessagesTabRoute on GoRouteData {
  static MessagesTabRoute _fromState(GoRouterState state) =>
      const MessagesTabRoute();

  @override
  String get location => GoRouteData.$location(
        '/messages',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MeTabRoute on GoRouteData {
  static MeTabRoute _fromState(GoRouterState state) => const MeTabRoute();

  @override
  String get location => GoRouteData.$location(
        '/me',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingsRoute => GoRouteData.$route(
      path: '/settings',
      name: 'settings',
      parentNavigatorKey: SettingsRoute.$parentNavigatorKey,
      factory: $SettingsRoute._fromState,
    );

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $flightDataSourcesRoute => GoRouteData.$route(
      path: '/settings/data-sources',
      name: 'flightDataSources',
      parentNavigatorKey: FlightDataSourcesRoute.$parentNavigatorKey,
      factory: $FlightDataSourcesRoute._fromState,
    );

mixin $FlightDataSourcesRoute on GoRouteData {
  static FlightDataSourcesRoute _fromState(GoRouterState state) =>
      const FlightDataSourcesRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/data-sources',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $attributionsRoute => GoRouteData.$route(
      path: '/settings/attributions',
      name: 'attributions',
      parentNavigatorKey: AttributionsRoute.$parentNavigatorKey,
      factory: $AttributionsRoute._fromState,
    );

mixin $AttributionsRoute on GoRouteData {
  static AttributionsRoute _fromState(GoRouterState state) =>
      const AttributionsRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/attributions',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $resourcesRoute => GoRouteData.$route(
      path: '/resources',
      name: 'resources',
      parentNavigatorKey: ResourcesRoute.$parentNavigatorKey,
      factory: $ResourcesRoute._fromState,
    );

mixin $ResourcesRoute on GoRouteData {
  static ResourcesRoute _fromState(GoRouterState state) => ResourcesRoute(
        highlight: state.uri.queryParameters['highlight'],
      );

  ResourcesRoute get _self => this as ResourcesRoute;

  @override
  String get location => GoRouteData.$location(
        '/resources',
        queryParams: {
          if (_self.highlight != null) 'highlight': _self.highlight,
        },
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $loginRoute => GoRouteData.$route(
      path: '/auth/login',
      name: 'login',
      parentNavigatorKey: LoginRoute.$parentNavigatorKey,
      factory: $LoginRoute._fromState,
    );

mixin $LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location(
        '/auth/login',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $signUpRoute => GoRouteData.$route(
      path: '/auth/signup',
      name: 'signup',
      parentNavigatorKey: SignUpRoute.$parentNavigatorKey,
      factory: $SignUpRoute._fromState,
    );

mixin $SignUpRoute on GoRouteData {
  static SignUpRoute _fromState(GoRouterState state) => const SignUpRoute();

  @override
  String get location => GoRouteData.$location(
        '/auth/signup',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $profileRoute => GoRouteData.$route(
      path: '/profile/:handle',
      name: 'profile',
      parentNavigatorKey: ProfileRoute.$parentNavigatorKey,
      factory: $ProfileRoute._fromState,
    );

mixin $ProfileRoute on GoRouteData {
  static ProfileRoute _fromState(GoRouterState state) => ProfileRoute(
        handle: state.pathParameters['handle']!,
      );

  ProfileRoute get _self => this as ProfileRoute;

  @override
  String get location => GoRouteData.$location(
        '/profile/${Uri.encodeComponent(_self.handle)}',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $threadRoute => GoRouteData.$route(
      path: '/threads/:threadId',
      name: 'thread',
      parentNavigatorKey: ThreadRoute.$parentNavigatorKey,
      factory: $ThreadRoute._fromState,
    );

mixin $ThreadRoute on GoRouteData {
  static ThreadRoute _fromState(GoRouterState state) => ThreadRoute(
        threadId: state.pathParameters['threadId']!,
        $extra: state.extra as String?,
      );

  ThreadRoute get _self => this as ThreadRoute;

  @override
  String get location => GoRouteData.$location(
        '/threads/${Uri.encodeComponent(_self.threadId)}',
      );

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $createPostRoute => GoRouteData.$route(
      path: '/posts/new',
      name: 'createPost',
      parentNavigatorKey: CreatePostRoute.$parentNavigatorKey,
      factory: $CreatePostRoute._fromState,
    );

mixin $CreatePostRoute on GoRouteData {
  static CreatePostRoute _fromState(GoRouterState state) => CreatePostRoute(
        $extra: state.extra as CreatePostDraft?,
      );

  CreatePostRoute get _self => this as CreatePostRoute;

  @override
  String get location => GoRouteData.$location(
        '/posts/new',
      );

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $postRoute => GoRouteData.$route(
      path: '/posts/:postId',
      name: 'post',
      parentNavigatorKey: PostRoute.$parentNavigatorKey,
      factory: $PostRoute._fromState,
    );

mixin $PostRoute on GoRouteData {
  static PostRoute _fromState(GoRouterState state) => PostRoute(
        postId: state.pathParameters['postId']!,
      );

  PostRoute get _self => this as PostRoute;

  @override
  String get location => GoRouteData.$location(
        '/posts/${Uri.encodeComponent(_self.postId)}',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
