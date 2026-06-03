import 'package:auth_api_client/auth_api_client.dart';
import 'package:auth_repository/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/app/router/root_navigator_key.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';
import 'package:where_to_fly/settings/view/settings_page.dart';
import 'helpers/auth_router_test_helper.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SettingsCubit settingsCubit;
  late _MockAuthRepository authRepository;
  late AuthCubit authCubit;

  setUpAll(initAuthRouterTestDependencies);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final settingsRepository = SettingsRepository(
      Storage(await SharedPreferences.getInstance()),
    );
    settingsCubit = SettingsCubit(settingsRepository);
    authRepository = _MockAuthRepository();
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
    authCubit = AuthCubit(authRepository);
    await authCubit.checkSession();
  });

  tearDown(() {
    authCubit.close();
    settingsCubit.close();
  });

  test('settings route uses the root navigator for shell overlays', () {
    expect(SettingsRoute.$parentNavigatorKey, rootNavigatorKey);
  });

  testWidgets('popping settings after push does not throw', (tester) async {
    final router = await pumpAuthAppRouter(
      tester,
      authCubit: authCubit,
      authRepository: authRepository,
      initialLocation: const ExploreTabRoute().location,
      extraBlocProviders: [BlocProvider.value(value: settingsCubit)],
    );
    await tester.pumpAndSettle();

    final context = router.routerDelegate.navigatorKey.currentContext!;
    await const SettingsRoute().push<void>(context);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
