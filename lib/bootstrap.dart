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
import 'package:media_kit/media_kit.dart';
import 'package:messaging_api_client/messaging_api_client.dart';
import 'package:messaging_repository/messaging_repository.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:social_api_client/social_api_client.dart';
import 'package:social_repository/social_repository.dart';
import 'package:storage/storage.dart';
import 'package:weather_api_client/weather_api_client.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/app/app.dart';
import 'package:where_to_fly/config/api_config.dart';
import 'package:where_to_fly/messaging/push/push_registration_service.dart';
import 'package:where_to_fly/zone_sync/zone_sync_service.dart';
import 'package:zones_api_client/zones_api_client.dart';

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

/// Wires up the layers (data clients -> repositories) and runs the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  if (kDebugMode) {
    Bloc.observer = const AppBlocObserver();
  }

  // Data layer.
  final storage = await Storage.getInstance();

  // Optional live zone feeds. Provide any combination with:
  //   --dart-define=ZONES_FEED_URL=https://.../zones.geojson
  //   --dart-define=OPENAIP_API_KEY=<your key>
  //   --dart-define=MADHEL_ENABLED=false   (live MADHEL refresh; on by default)
  // When set, live feeds overlay the bundled offline snapshot by id. Feeds that
  // error are ignored; bundled zones always remain as the baseline.
  const zonesFeedUrl = String.fromEnvironment('ZONES_FEED_URL');
  const openAipApiKey = String.fromEnvironment('OPENAIP_API_KEY');
  const madhelEnabled =
      bool.fromEnvironment('MADHEL_ENABLED', defaultValue: true);
  final apiBaseUri = resolveApiBaseUri();
  if (kDebugMode) {
    log('API base URL: $apiBaseUri');
    if (apiBaseUriNeedsPhysicalDeviceOverride) {
      log('WARNING: ${physicalDeviceApiHint()}');
    }
  }

  // Repository layer (each composes its data clients).
  final settingsRepository = SettingsRepository(storage);
  final authApiClient = AuthApiClient(baseUrl: apiBaseUri);
  final authRepository = AuthRepository(
    apiClient: authApiClient,
    storage: storage,
  );
  Future<String?> accessToken() => authRepository.accessToken();
  final weatherRepository = WeatherRepository(
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

  ZonesFeedClient? geojsonClient;
  if (zonesFeedUrl.isNotEmpty) {
    geojsonClient = RemoteZonesApiClient(url: Uri.parse(zonesFeedUrl));
  } else if (await authRepository.currentSession() != null) {
    geojsonClient = backendZonesClient;
  }

  final flightRulesRepository = await FlightRulesRepository.load(
    geojson: geojsonClient,
    openaip: openAipApiKey.isEmpty
        ? null
        : OpenAipZonesApiClient(apiKey: openAipApiKey),
    madhel: madhelEnabled ? MadhelZonesApiClient() : null,
  );
  const locationRepository = LocationRepository();
  final geocodingRepository = GeocodingRepository(
    apiClient: GeocodingApiClient(),
    storage: storage,
  );

  runApp(
    App(
      settingsRepository: settingsRepository,
      flightRulesRepository: flightRulesRepository,
      locationRepository: locationRepository,
      geocodingRepository: geocodingRepository,
      authRepository: authRepository,
      weatherRepository: weatherRepository,
      socialRepository: socialRepository,
      messagingRepository: messagingRepository,
      pushRegistrationService: pushRegistrationService,
      zoneSyncService: zoneSyncService,
    ),
  );
}
