import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';

import 'helpers/app_mode_test_helper.dart';
import 'helpers/pump_helpers.dart';

void main() {
  setUp(withFullAppModeForTests);
  tearDown(restoreAppModeAfterTests);

  testWidgets('navigateAfterAuthentication deep link uses go without error',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/auth/login?returnTo=/map',
      routes: [
        GoRoute(
          path: '/map',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Map'))),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Login')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );
    await tester.pump();

    navigateAfterAuthentication(
      tester.element(find.text('Login')),
    );
    await tester.pump();
    await pumpRouterFrames(tester, frames: 3);

    expect(router.state.uri.path, '/map');
    expect(tester.takeException(), isNull);
  });
}
