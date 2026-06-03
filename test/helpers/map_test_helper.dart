import 'package:auth_repository/auth_repository.dart';
import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_repository/location_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/view/map_page.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';
import 'package:where_to_fly/zone_sync/zone_sync_service.dart';
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
      RepositoryProvider<FlightRulesRepository>.value(
        value: testFlightRulesRepository,
      ),
      RepositoryProvider<SettingsRepository>.value(
        value: testSettingsRepository,
      ),
      RepositoryProvider<GeocodingRepository>.value(
        value: geocodingRepository,
      ),
      RepositoryProvider<LocationRepository>.value(
        value: locationRepository,
      ),
      RepositoryProvider<AuthRepository>.value(value: authRepository),
      RepositoryProvider<WeatherRepository>.value(value: weatherRepository),
      RepositoryProvider<ZoneSyncService>.value(value: zoneSyncService),
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
