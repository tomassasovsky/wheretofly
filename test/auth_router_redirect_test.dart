import 'package:auth_api_client/auth_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';
import 'helpers/app_mode_test_helper.dart';
import 'helpers/auth_router_test_helper.dart';
import 'helpers/pump_helpers.dart';

void main() {
  late MockAuthRepository authRepository;
  late AuthCubit authCubit;

  setUpAll(initAuthRouterTestDependencies);

  setUp(() {
    withFullAppModeForTests();
    authRepository = MockAuthRepository();
    when(() => authRepository.currentSession()).thenAnswer((_) async => null);
    authCubit = AuthCubit(authRepository);
  });

  tearDown(() {
    restoreAppModeAfterTests();
    authCubit.close();
  });

  testWidgets('unauthenticated user on feed redirects to login with returnTo',
      (tester) async {
    await authCubit.checkSession();
    final router = await pumpAuthAppRouter(
      tester,
      authCubit: authCubit,
      authRepository: authRepository,
      initialLocation: const FeedTabRoute().location,
    );
    await pumpRouterFrames(tester);

    expect(router.state.uri.path, '/auth/login');
    expect(
      router.state.uri.queryParameters[returnToQueryKey],
      '/feed',
    );
  });

  testWidgets('unknown auth on feed redirects to splash', (tester) async {
    final router = await pumpAuthAppRouter(
      tester,
      authCubit: authCubit,
      authRepository: authRepository,
      initialLocation: const FeedTabRoute().location,
    );
    await tester.pump();

    expect(router.state.uri.path, const SplashRoute().location);
  });

  testWidgets('authenticated user on login redirects to map', (tester) async {
    when(() => authRepository.currentSession()).thenAnswer(
      (_) async => const AuthSession(
        accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJzdWIiOiJ1MSIsImhhbmRsZSI6InBlcGUiLCJleHAiOjk5OTk5OTk5OTl9.'
            'sig',
        refreshToken: 'refresh',
        expiresInSeconds: 3600,
      ),
    );
    when(() => authRepository.validateStoredSession()).thenAnswer((_) async {});

    final sessionCubit = AuthCubit(authRepository);
    addTearDown(sessionCubit.close);
    await sessionCubit.checkSession();

    final router = await pumpAuthAppRouter(
      tester,
      authCubit: sessionCubit,
      authRepository: authRepository,
      initialLocation: const LoginRoute().location,
    );
    await pumpRouterFrames(tester);

    expect(router.state.uri.path, const MapTabRoute().location);
  });

  testWidgets('authenticated user on login honors returnTo', (tester) async {
    when(() => authRepository.currentSession()).thenAnswer(
      (_) async => const AuthSession(
        accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJzdWIiOiJ1MSIsImhhbmRsZSI6InBlcGUiLCJleHAiOjk5OTk5OTk5OTl9.'
            'sig',
        refreshToken: 'refresh',
        expiresInSeconds: 3600,
      ),
    );
    when(() => authRepository.validateStoredSession()).thenAnswer((_) async {});

    final sessionCubit = AuthCubit(authRepository);
    addTearDown(sessionCubit.close);
    await sessionCubit.checkSession();

    final router = await pumpAuthAppRouter(
      tester,
      authCubit: sessionCubit,
      authRepository: authRepository,
      initialLocation: '/auth/login?returnTo=/messages',
    );
    await pumpRouterFrames(tester);

    expect(router.state.uri.path, '/messages');
  });

  testWidgets('map is reachable without authentication', (tester) async {
    await authCubit.checkSession();
    final router = await pumpAuthAppRouter(
      tester,
      authCubit: authCubit,
      authRepository: authRepository,
      initialLocation: const MapTabRoute().location,
    );
    await pumpRouterFrames(tester);

    expect(router.state.uri.path, const MapTabRoute().location);
  });
}
