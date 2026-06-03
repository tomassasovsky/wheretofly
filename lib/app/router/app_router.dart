import 'package:go_router/go_router.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/app/router/root_navigator_key.dart';

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: const MapTabRoute().location,
    redirect: (context, state) {
      if (state.uri.path == '/') return const MapTabRoute().location;
      return null;
    },
    routes: $appRoutes,
  );
}
