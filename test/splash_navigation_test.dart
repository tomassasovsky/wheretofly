import 'package:auth_api_client/auth_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/view/login_page.dart';
import 'package:where_to_fly/auth/view/splash_page.dart';
import 'helpers/auth_router_test_helper.dart';

void main() {
  late MockAuthRepository authRepository;

  setUpAll(initAuthRouterTestDependencies);

  setUp(() {
    authRepository = MockAuthRepository();
  });

  testWidgets('splash navigates to login when session is absent',
      (tester) async {
    when(() => authRepository.currentSession()).thenAnswer((_) async => null);

    final authCubit = AuthCubit(authRepository);
    addTearDown(authCubit.close);

    final router = await pumpAuthAppRouter(
      tester,
      authCubit: authCubit,
      authRepository: authRepository,
      initialLocation: const SplashRoute().location,
    );
    await authCubit.checkSession();
    await tester.pumpAndSettle();

    expect(find.byType(SplashPage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(router.state.uri.path, const LoginRoute().location);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash navigates to map when session is valid', (tester) async {
    const session = AuthSession(
      accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiJ1MSIsImhhbmRsZSI6InBlcGUiLCJleHAiOjk5OTk5OTk5OTl9.'
          'sig',
      refreshToken: 'refresh',
      expiresInSeconds: 3600,
    );
    when(() => authRepository.currentSession())
        .thenAnswer((_) async => session);
    when(() => authRepository.validateStoredSession()).thenAnswer((_) async {});

    final authCubit = AuthCubit(authRepository);
    addTearDown(authCubit.close);

    final router = await pumpAuthAppRouter(
      tester,
      authCubit: authCubit,
      authRepository: authRepository,
      initialLocation: const SplashRoute().location,
    );
    await authCubit.checkSession();
    await tester.pumpAndSettle();

    expect(find.byType(SplashPage), findsNothing);
    expect(router.state.uri.path, const MapTabRoute().location);
    expect(tester.takeException(), isNull);
  });
}
