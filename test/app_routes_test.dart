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
import 'package:where_to_fly/resources/view/resources_page.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';
import 'package:where_to_fly/settings/view/settings_page.dart';

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

  Future<void> pumpRouter(
    WidgetTester tester, {
    required String initialLocation,
  }) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: settingsCubit,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            navigatorKey: rootNavigatorKey,
            initialLocation: initialLocation,
            routes: $appRoutes,
          ),
        ),
      ),
    );
    await pumpRouterFrames(tester);
  }

  testWidgets('navigates to settings route', (tester) async {
    await pumpRouter(tester, initialLocation: const SettingsRoute().location);

    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('resources route passes highlight query parameter',
      (tester) async {
    await pumpRouter(
      tester,
      initialLocation: const ResourcesRoute(
        highlight: 'authorized_commercial',
      ).location,
    );

    final page = tester.widget<ResourcesPage>(find.byType(ResourcesPage));
    expect(page.highlightPermission?.id, 'authorized_commercial');
  });
}
