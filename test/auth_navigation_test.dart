import 'package:auth_api_client/auth_api_client.dart';
import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';
import 'package:where_to_fly/auth/view/login_page.dart';
import 'package:where_to_fly/auth/view/signup_page.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _demoSession = AuthSession(
  accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJzdWIiOiJ1MSIsImhhbmRsZSI6InBlcGUiLCJleHAiOjk5OTk5OTk5OTl9.'
      'sig',
  refreshToken: 'refresh',
  expiresInSeconds: 3600,
);

List<RouteBase> _authTestRoutes() => [
      GoRoute(
        path: '/map',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Map tab'))),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Feed tab'))),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Messages tab'))),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignUpPage(),
      ),
    ];

void main() {
  late AuthCubit authCubit;
  late _MockAuthRepository authRepository;

  setUp(() {
    authRepository = _MockAuthRepository();
    when(() => authRepository.currentSession()).thenAnswer((_) async => null);
    authCubit = AuthCubit(authRepository);
  });

  Future<GoRouter> pumpAuthRouter(
    WidgetTester tester, {
    required String initialLocation,
  }) async {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: _authTestRoutes(),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: authCubit,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('authReturnDestination falls back to map for invalid returnTo',
      (tester) async {
    final router = await pumpAuthRouter(
      tester,
      initialLocation: '/auth/login?returnTo=/settings',
    );
    expect(authReturnDestination(router), const MapTabRoute().location);
  });

  testWidgets('authReturnDestination preserves shell tab returnTo',
      (tester) async {
    final router = await pumpAuthRouter(
      tester,
      initialLocation: '/auth/login?returnTo=/feed',
    );
    expect(authReturnDestination(router), '/feed');
  });

  testWidgets('login success pops back to the originating shell tab',
      (tester) async {
    final router = await pumpAuthRouter(
      tester,
      initialLocation: '/map',
    );

    openLogin(tester.element(find.text('Map tab')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/auth/login');

    when(
      () => authRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _demoSession);

    await authCubit.login(email: 'pilot@dev.local', password: 'password123');
    await tester.pumpAndSettle();

    expect(authCubit.state.isAuthenticated, isTrue);
    expect(router.state.uri.path, '/map');
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('signup replaces login so success returns to shell tab',
      (tester) async {
    final router = await pumpAuthRouter(
      tester,
      initialLocation: '/messages',
    );

    openLogin(tester.element(find.text('Messages tab')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Need an account? Sign up'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/auth/signup');
    expect(find.byType(LoginPage), findsNothing);

    when(
      () => authRepository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        handle: any(named: 'handle'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => _demoSession);

    await authCubit.signUp(
      email: 'new@dev.local',
      password: 'password123',
      handle: 'newpilot',
      displayName: 'New Pilot',
    );
    await tester.pumpAndSettle();

    expect(authCubit.state.isAuthenticated, isTrue);
    expect(router.state.uri.path, '/messages');
    expect(find.byType(SignUpPage), findsNothing);
  });

  testWidgets('deep-linked login without stack goes to returnTo tab',
      (tester) async {
    final router = await pumpAuthRouter(
      tester,
      initialLocation: '/auth/login?returnTo=/feed',
    );

    when(
      () => authRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _demoSession);

    await authCubit.login(email: 'pilot@dev.local', password: 'password123');
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/feed');
    expect(find.byType(LoginPage), findsNothing);
  });
}
