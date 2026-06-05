import 'dart:async';
import 'dart:developer';

import 'package:auth_api_client/auth_api_client.dart';
import 'package:auth_repository/auth_repository.dart';
import 'package:backend_zones_api_client/backend_zones_api_client.dart';
import 'package:bloc/bloc.dart';
import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding_api_client/geocoding_api_client.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:location_repository/location_repository.dart';
import 'package:messaging_api_client/messaging_api_client.dart';
import 'package:messaging_repository/messaging_repository.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:social_api_client/social_api_client.dart';
import 'package:social_repository/social_repository.dart';
import 'package:storage/storage.dart';
import 'package:wasm_run_flutter/wasm_run_flutter.dart';
import 'package:weather_api_client/weather_api_client.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/app/app.dart';
import 'package:where_to_fly/config/api_config.dart';
import 'package:where_to_fly/map/wind_map_config.dart';
import 'package:where_to_fly/legal/register_app_licenses.dart';
import 'package:where_to_fly/map/wind/om/om_wasm_module.dart';
import 'package:where_to_fly/map/wind/om/wind_decode_support.dart';
import 'package:where_to_fly/messaging/push/push_registration_service.dart';
import 'package:where_to_fly/zone_sync/zone_sync_service.dart';

/// Observes all Bloc/Cubit state changes and errors for debugging.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

/// Root widget plus [SettingsRepository] after wiring dependencies.
class AppDependencies {
  const AppDependencies({
    required this.app,
    required this.settingsRepository,
  });

  final App app;
  final SettingsRepository settingsRepository;
}

/// Licenses, WASM, and wind layer setup. Call before [buildApp] / [runApp].
Future<void> initializeAppPlatform() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerAppLicenses();
  WasmRunFlutterNative.registerWith();
  if (WindMapConfig.enabled) {
    try {
      if (await WindDecodeSupport.localOmWasmWorks()) {
        await OmWasmModule.ensureInitialized();
        if (kDebugMode) {
          log('Open-Meteo om WASM ready (local decode)');
        }
      } else {
        const explicitWindTiles = String.fromEnvironment('WIND_TILE_BASE_URL');
        if (explicitWindTiles.isEmpty) {
          final api = resolveApiBaseUri();
          WindMapConfig.useRemoteTileBaseUrl('${api.origin}/v1/wind/tiles');
        }
        if (kDebugMode) {
          log(
            'Wind layer will fetch PNG tiles from '
            '${WindMapConfig.windTileBaseUrl}',
          );
        }
      }
    } on Object catch (error, stackTrace) {
      log('Open-Meteo om WASM init failed: $error', stackTrace: stackTrace);
    }
  }
}

/// Wires data clients and repositories; does not call [runApp].
Future<AppDependencies> buildApp({WeatherRepository? weatherRepository}) async {
  final storage = await Storage.getInstance();
  final secureStorage = SecureStorage();
  final apiBaseUri = resolveApiBaseUri();
  if (kDebugMode) {
    log('API base URL: $apiBaseUri');
    if (apiBaseUriNeedsPhysicalDeviceOverride) {
      log('WARNING: ${physicalDeviceApiHint()}');
    }
  }

  final settingsRepository = SettingsRepository(storage);
  final authApiClient = AuthApiClient(baseUrl: apiBaseUri);
  final authRepository = AuthRepository(
    apiClient: authApiClient,
    secureStorage: secureStorage,
  );
  Future<String?> accessToken() => authRepository.accessToken();
  final weather = weatherRepository ??
      WeatherRepository(
        apiClient: WeatherApiClient(
          baseUrl: apiBaseUri,
          accessTokenProvider: accessToken,
        ),
      );
  final socialRepository = SocialRepository(
    apiClient: SocialApiClient(
      baseUrl: apiBaseUri,
      accessTokenProvider: accessToken,
    ),
  );
  final messagingRepository = MessagingRepository(
    apiClient: MessagingApiClient(
      baseUrl: apiBaseUri,
      accessTokenProvider: accessToken,
    ),
  );
  final pushRegistrationService = PushRegistrationService(
    messagingRepository: messagingRepository,
    authRepository: authRepository,
  );
  final backendZonesClient = BackendZonesApiClient(
    baseUrl: apiBaseUri,
    accessTokenProvider: accessToken,
    storage: storage,
  );
  final zoneSyncService = ZoneSyncService(
    backendZonesClient: backendZonesClient,
  );

  final flightRulesRepository = await FlightRulesRepository.load(
    feed: backendZonesClient,
  );
  const locationRepository = LocationRepository();
  final geocodingRepository = GeocodingRepository(
    apiClient: GeocodingApiClient(baseUrl: apiBaseUri),
    storage: storage,
  );

  return AppDependencies(
    settingsRepository: settingsRepository,
    app: App(
      settingsRepository: settingsRepository,
      flightRulesRepository: flightRulesRepository,
      locationRepository: locationRepository,
      geocodingRepository: geocodingRepository,
      authRepository: authRepository,
      weatherRepository: weather,
      socialRepository: socialRepository,
      messagingRepository: messagingRepository,
      pushRegistrationService: pushRegistrationService,
      zoneSyncService: zoneSyncService,
    ),
  );
}

/// Wires up the layers (data clients -> repositories) and runs the app.
Future<void> bootstrap() async {
  await initializeAppPlatform();

  final previousFlutterOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
    previousFlutterOnError?.call(details);
  };

  if (kDebugMode) {
    Bloc.observer = const AppBlocObserver();
  }

  final deps = await buildApp();
  runApp(deps.app);
}
