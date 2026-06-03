import 'package:auth_repository/auth_repository.dart';
import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:location_repository/location_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/app/router/app_router.dart';
import 'package:where_to_fly/app/router/router_auth_refresh.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/zone_sync/zone_sync_service.dart';
import 'package:zones_api_client/zones_api_client.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

class MockLocationRepository extends Mock implements LocationRepository {}

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockZoneSyncService extends Mock implements ZoneSyncService {}

class _EmptyFeed implements ZonesFeedClient {
  @override
  Future<List<ZoneData>> fetchZones() async => [];
}

class _EmptyBundled extends BundledZonesApiClient {
  @override
  Future<List<ZoneData>> fetchZones() async => [];
}

late FlightRulesRepository testFlightRulesRepository;
late SettingsRepository testSettingsRepository;

Future<void> initAuthRouterTestDependencies() async {
  SharedPreferences.setMockInitialValues({});
  testFlightRulesRepository = await FlightRulesRepository.load(
    feed: _EmptyFeed(),
    offlineFallback: _EmptyBundled(),
  );
  testSettingsRepository = SettingsRepository(
    Storage(await SharedPreferences.getInstance()),
  );
}

Widget buildAuthRouterTestApp({
  required AuthCubit authCubit,
  required AuthRepository authRepository,
  required GoRouter router,
  List<BlocProvider> extraBlocProviders = const [],
}) {
  final geocodingRepository = MockGeocodingRepository();
  final locationRepository = MockLocationRepository();
  final weatherRepository = MockWeatherRepository();
  final zoneSyncService = MockZoneSyncService();

  when(zoneSyncService.syncZones).thenAnswer((_) async => []);
  when(() => zoneSyncService.lastMetadata).thenReturn(const ZoneFeedMetadata());

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
        ...extraBlocProviders,
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
}

Future<GoRouter> pumpAuthAppRouter(
  WidgetTester tester, {
  required AuthCubit authCubit,
  required AuthRepository authRepository,
  String? initialLocation,
  List<BlocProvider> extraBlocProviders = const [],
}) async {
  final refresh = RouterAuthRefresh(authCubit);
  addTearDown(refresh.dispose);

  final router = createAppRouter(refreshListenable: refresh);
  if (initialLocation != null) {
    router.go(initialLocation);
  }

  await tester.pumpWidget(
    buildAuthRouterTestApp(
      authCubit: authCubit,
      authRepository: authRepository,
      router: router,
      extraBlocProviders: extraBlocProviders,
    ),
  );
  await tester.pump();
  return router;
}
