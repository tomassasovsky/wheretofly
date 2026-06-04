import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/app/router/root_navigator_key.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';

import 'helpers/pump_helpers.dart';

void main() {
  late SettingsCubit settingsCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final repository = SettingsRepository(
      Storage(await SharedPreferences.getInstance()),
    );
    settingsCubit = SettingsCubit(repository);
  });

  Future<void> pumpSettingsPage(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: settingsCubit,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            navigatorKey: rootNavigatorKey,
            initialLocation: const SettingsRoute().location,
            routes: $appRoutes,
          ),
        ),
      ),
    );
    await pumpRouterFrames(tester);
  }

  testWidgets('shows theme and language controls', (tester) async {
    await pumpSettingsPage(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
  });

  testWidgets('hides log in while map-only mode', (tester) async {
    await pumpSettingsPage(tester);

    expect(find.text('Log in'), findsNothing);
    expect(find.text('Account'), findsNothing);
  });

  testWidgets('shows permits and resources entry', (tester) async {
    await pumpSettingsPage(tester);

    expect(find.text('Permits and resources'), findsOneWidget);
    expect(
      find.text('Permits, guides, and official links'),
      findsOneWidget,
    );
  });

  testWidgets('shows sponsor me button', (tester) async {
    await pumpSettingsPage(tester);

    expect(find.text('Sponsor me'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Support development on Cafecito.'),
      200,
    );
    expect(find.text('Support development on Cafecito.'), findsOneWidget);
    expect(find.byIcon(Icons.local_cafe_outlined), findsOneWidget);
  });

  testWidgets('updates theme when segmented button changes', (tester) async {
    await pumpSettingsPage(tester);

    await tester.tap(find.text('Dark'));
    await pumpRouterFrames(tester, frames: 3);

    expect(settingsCubit.state.themeMode, ThemeMode.dark);
  });

  testWidgets('updates language when a language tile is tapped',
      (tester) async {
    await pumpSettingsPage(tester);

    await tester.tap(find.text('Español'));
    await pumpRouterFrames(tester, frames: 3);

    expect(settingsCubit.state.locale?.languageCode, 'es');
  });
}
