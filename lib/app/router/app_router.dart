import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/app/router/root_navigator_key.dart';

GoRouter createAppRouter({required Listenable refreshListenable}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: const SplashRoute().location,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      if (state.uri.path == '/') return const MapTabRoute().location;
      return null;
    },
    routes: $appRoutes,
  );
}
