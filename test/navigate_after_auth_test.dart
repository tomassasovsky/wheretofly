import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';

void main() {
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
    await tester.pumpAndSettle();

    navigateAfterAuthentication(
      tester.element(find.text('Login')),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/map');
    expect(tester.takeException(), isNull);
  });
}
