import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/view/map_page.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';
import 'package:zones_api_client/zones_api_client.dart';

import 'auth_router_test_helper.dart';

Future<void> initMapTestDependencies() async {
  registerFallbackValue(const LatLng(0, 0));
  await initAuthRouterTestDependencies();
}

Widget buildMapPageTestWidget({
  required AuthCubit authCubit,
  required AuthRepository authRepository,
}) {
  final geocodingRepository = MockGeocodingRepository();
  final locationRepository = MockLocationRepository();
  final weatherRepository = MockWeatherRepository();
  final zoneSyncService = MockZoneSyncService();

  when(zoneSyncService.syncZones).thenAnswer((_) async => []);
  when(() => zoneSyncService.lastMetadata).thenReturn(const ZoneFeedMetadata());
  when(() => weatherRepository.getWeather(any()))
      .thenThrow(UnimplementedError());

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: testFlightRulesRepository),
      RepositoryProvider.value(value: testSettingsRepository),
      RepositoryProvider.value(value: geocodingRepository),
      RepositoryProvider.value(value: locationRepository),
      RepositoryProvider.value(value: authRepository),
      RepositoryProvider.value(value: weatherRepository),
      RepositoryProvider.value(value: zoneSyncService),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
        BlocProvider(
          create: (_) => SettingsCubit(testSettingsRepository),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MapPage(),
      ),
    ),
  );
}
