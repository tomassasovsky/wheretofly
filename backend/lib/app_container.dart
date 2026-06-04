import 'dart:io';

import 'package:backend/config/app_config.dart';
import 'package:backend/db/database.dart';
import 'package:backend/util/zone_feed_path.dart';
import 'package:backend/services/auth_service.dart';
import 'package:backend/services/geocoding_service.dart';
import 'package:backend/services/jwt_service.dart';
import 'package:backend/services/messaging_service.dart';
import 'package:backend/services/notification_service.dart';
import 'package:backend/services/post_service.dart';
import 'package:backend/services/weather_alert_service.dart';
import 'package:backend/services/weather_service.dart';
import 'package:backend/services/zone_ingest_service.dart';
import 'package:backend/services/zone_service.dart';
import 'package:zones_api_client/zones_api_client.dart';

/// Application-wide dependency container.
class AppContainer {
  AppContainer._({
    required this.config,
    required this.database,
    required this.jwtService,
    required this.authService,
    required this.weatherService,
    required this.weatherAlertService,
    required this.geocodingService,
    required this.zoneService,
    required this.zoneIngestService,
    required this.postService,
    required this.messagingService,
    required this.notificationService,
  });

  static AppContainer? _instance;

  /// Runtime configuration loaded from the environment.
  final AppConfig config;

  /// PostgreSQL connection and migration runner.
  final Database database;

  /// JWT access-token issuer and verifier.
  final JwtService jwtService;

  /// Email/password auth and account lifecycle.
  final AuthService authService;

  /// Open-Meteo and SMN weather proxy.
  final WeatherService weatherService;

  /// Saved weather alert subscriptions and worker.
  final WeatherAlertService weatherAlertService;

  /// Self-hosted Photon geocoding proxy for map search.
  final GeocodingService geocodingService;

  /// Zone GeoJSON feed with versioning.
  final ZoneService zoneService;

  /// Bundled + live zone ingest pipeline.
  final ZoneIngestService zoneIngestService;

  /// Social posts, comments, and follows.
  final PostService postService;

  /// Direct and group messaging.
  final MessagingService messagingService;

  /// Device tokens and push dispatch.
  final NotificationService notificationService;

  /// Returns the initialized container or throws if not yet set up.
  static AppContainer get instance {
    final value = _instance;
    if (value == null) {
      throw StateError('AppContainer not initialized');
    }
    return value;
  }

  /// Connects to Postgres, runs migrations, and wires all services.
  static Future<AppContainer> initialize() async {
    if (_instance != null) return _instance!;
    final config = AppConfig.fromEnvironment();
    validateZoneFeedPath(config.zoneFeedPath);
    final database = await Database.connect(config);
    await database.runMigrations();
    final jwtService = JwtService(config);
    final authService = AuthService(database: database, config: config);
    final weatherService = WeatherService();
    final geocodingService = GeocodingService(config: config);
    final zoneService = ZoneService(database: database, config: config);
    final openAip = config.openAipApiKey.isEmpty
        ? null
        : OpenAipZonesApiClient(apiKey: config.openAipApiKey);
    final zoneIngestService = ZoneIngestService(
      database: database,
      zoneService: zoneService,
      openaip: openAip,
    );
    await _ensureZoneFeedPublished(config, zoneIngestService);
    final notificationService = NotificationService(database: database);
    final weatherAlertService = WeatherAlertService(
      database: database,
      weatherService: weatherService,
      notificationService: notificationService,
    );
    final postService = PostService(database: database);
    final messagingService = MessagingService(database: database);
    _instance = AppContainer._(
      config: config,
      database: database,
      jwtService: jwtService,
      authService: authService,
      weatherService: weatherService,
      weatherAlertService: weatherAlertService,
      geocodingService: geocodingService,
      zoneService: zoneService,
      zoneIngestService: zoneIngestService,
      postService: postService,
      messagingService: messagingService,
      notificationService: notificationService,
    );
    return _instance!;
  }

  static Future<void> _ensureZoneFeedPublished(
    AppConfig config,
    ZoneIngestService zoneIngestService,
  ) async {
    final feedFile = File(config.zoneFeedPath);
    if (feedFile.existsSync() && feedFile.lengthSync() > 2) return;
    await zoneIngestService.ingestAndPublish(outputPath: config.zoneFeedPath);
  }

  /// Closes the database connection and clears the singleton.
  static Future<void> dispose() async {
    await _instance?.database.close();
    _instance = null;
  }
}
