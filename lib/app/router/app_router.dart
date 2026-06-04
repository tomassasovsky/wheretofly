import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:where_to_fly/app/app_mode.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/app/router/root_navigator_key.dart';

const _socialShellPaths = {'/feed', '/explore', '/messages', '/me'};

String get _mapLocation => const MapTabRoute().location;

bool _isSocialPath(String path) {
  if (_socialShellPaths.contains(path)) return true;
  if (path.startsWith('/profile/')) return true;
  if (path.startsWith('/posts/')) return true;
  if (path.startsWith('/threads/')) return true;
  return false;
}

GoRouter createAppRouter({required Listenable refreshListenable}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: const SplashRoute().location,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/') return _mapLocation;
      if (AppMode.mapOnly) {
        if (_isSocialPath(path)) return _mapLocation;
        if (path.startsWith('/auth/')) return _mapLocation;
      }
      return null;
    },
    routes: $appRoutes,
  );
}
