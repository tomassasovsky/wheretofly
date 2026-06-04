import 'package:auth_repository/auth_repository.dart';
import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_repository/location_repository.dart';
import 'package:messaging_repository/messaging_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/app/router/app_router.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/app/router/router_auth_refresh.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/view/widgets/flutter_map_layer.dart';
import 'package:where_to_fly/map/wind_map_config.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';
import 'package:where_to_fly/zone_sync/zone_sync_service.dart';
import 'package:zones_api_client/zones_api_client.dart';

import 'map_test_flutter_errors.dart';
import 'pump_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

class MockLocationRepository extends Mock implements LocationRepository {}

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockZoneSyncService extends Mock implements ZoneSyncService {}

class MockMessagingRepository extends Mock implements MessagingRepository {}

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
  installMapTestFlutterErrorHandler();
  FlutterMapLayer.debugSkipNetworkTiles = true;
  WindMapConfig.enabledOverride = false;
  SharedPreferences.setMockInitialValues({});
  registerFallbackValue(const LatLng(0, 0));
  testFlightRulesRepository = await FlightRulesRepository.load(
    feed: _EmptyFeed(),
    offlineFallback: _EmptyBundled(),
  );
  testSettingsRepository = SettingsRepository(
    Storage(await SharedPreferences.getInstance()),
  );
}

void _stubMapDependencies({
  required MockGeocodingRepository geocodingRepository,
  required MockLocationRepository locationRepository,
  required MockWeatherRepository weatherRepository,
  required MockZoneSyncService zoneSyncService,
}) {
  when(zoneSyncService.syncZones).thenAnswer((_) async => []);
  when(() => zoneSyncService.lastMetadata).thenReturn(const ZoneFeedMetadata());
  when(() => geocodingRepository.search(any())).thenAnswer((_) async => []);
  when(() => weatherRepository.getWeather(any())).thenThrow(
    UnimplementedError('weather not stubbed'),
  );
}

Widget buildAuthRouterTestApp({
  required AuthCubit authCubit,
  required AuthRepository authRepository,
  required GoRouter router,
  required MockGeocodingRepository geocodingRepository,
  required MockLocationRepository locationRepository,
  required MockWeatherRepository weatherRepository,
  required MockZoneSyncService zoneSyncService,
  required MockMessagingRepository messagingRepository,
  List<BlocProvider> extraBlocProviders = const [],
}) {
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
      RepositoryProvider<WeatherRepository>.value(
        value: weatherRepository,
      ),
      RepositoryProvider<ZoneSyncService>.value(value: zoneSyncService),
      RepositoryProvider<MessagingRepository>.value(
        value: messagingRepository,
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
        BlocProvider(
          create: (_) => SettingsCubit(testSettingsRepository),
        ),
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
  final geocodingRepository = MockGeocodingRepository();
  final locationRepository = MockLocationRepository();
  final weatherRepository = MockWeatherRepository();
  final zoneSyncService = MockZoneSyncService();
  final messagingRepository = MockMessagingRepository();
  when(messagingRepository.threads).thenAnswer((_) async => []);

  _stubMapDependencies(
    geocodingRepository: geocodingRepository,
    locationRepository: locationRepository,
    weatherRepository: weatherRepository,
    zoneSyncService: zoneSyncService,
  );

  final router = createAppRouter(
    refreshListenable: refresh,
    initialLocation: initialLocation ?? const MapTabRoute().location,
  );
  await tester.pumpWidget(
    buildAuthRouterTestApp(
      authCubit: authCubit,
      authRepository: authRepository,
      router: router,
      geocodingRepository: geocodingRepository,
      locationRepository: locationRepository,
      weatherRepository: weatherRepository,
      zoneSyncService: zoneSyncService,
      messagingRepository: messagingRepository,
      extraBlocProviders: extraBlocProviders,
    ),
  );
  await tester.pump();
  FlutterMapLayer.debugSkipNetworkTiles = true;

  addTearDown(() async {
    await resetWidgetTree(tester);
    refresh.dispose();
    router.dispose();
  });
  return router;
}
