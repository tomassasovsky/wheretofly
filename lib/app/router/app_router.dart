import 'package:go_router/go_router.dart';
import 'package:where_to_fly/app/router/app_routes.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: const MapTabRoute().location,
    redirect: (context, state) {
      if (state.uri.path == '/') return const MapTabRoute().location;
      return null;
    },
    routes: $appRoutes,
  );
}
