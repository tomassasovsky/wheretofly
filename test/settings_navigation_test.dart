import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';
import 'package:where_to_fly/app/router/app_router.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';
import 'package:where_to_fly/settings/view/settings_page.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SettingsCubit settingsCubit;
  late AuthCubit authCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final settingsRepository = SettingsRepository(
      Storage(await SharedPreferences.getInstance()),
    );
    settingsCubit = SettingsCubit(settingsRepository);
    authCubit = AuthCubit(_MockAuthRepository());
  });

  test('settings route uses the root navigator for shell overlays', () {
    expect(SettingsRoute.$parentNavigatorKey, rootNavigatorKey);
  });

  testWidgets('popping settings after push does not throw', (tester) async {
    final router = createAppRouter();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settingsCubit),
          BlocProvider.value(value: authCubit),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.go(const MeTabRoute().location);
    await tester.pumpAndSettle();

    final context = router.routerDelegate.navigatorKey.currentContext!;
    await const SettingsRoute().push<void>(context);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    await router.pop();
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
