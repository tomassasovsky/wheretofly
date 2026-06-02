import 'package:backend/config/app_config.dart';
import 'package:backend/db/database.dart';
import 'package:backend/services/auth_service.dart';
import 'package:backend/services/jwt_service.dart';
import 'package:backend/services/messaging_service.dart';
import 'package:backend/services/notification_service.dart';
import 'package:backend/services/post_service.dart';
import 'package:backend/services/weather_alert_service.dart';
import 'package:backend/services/weather_service.dart';
import 'package:backend/services/zone_ingest_service.dart';
import 'package:backend/services/zone_service.dart';

/// Application-wide dependency container.
class AppContainer {
  AppContainer._({
    required this.config,
    required this.database,
    required this.jwtService,
    required this.authService,
    required this.weatherService,
    required this.weatherAlertService,
    required this.zoneService,
    required this.zoneIngestService,
    required this.postService,
    required this.messagingService,
    required this.notificationService,
  });

  static AppContainer? _instance;

  final AppConfig config;
  final Database database;
  final JwtService jwtService;
  final AuthService authService;
  final WeatherService weatherService;
  final WeatherAlertService weatherAlertService;
  final ZoneService zoneService;
  final ZoneIngestService zoneIngestService;
  final PostService postService;
  final MessagingService messagingService;
  final NotificationService notificationService;

  static AppContainer get instance {
    final value = _instance;
    if (value == null) {
      throw StateError('AppContainer not initialized');
    }
    return value;
  }

  static Future<AppContainer> initialize() async {
    if (_instance != null) return _instance!;
    final config = AppConfig.fromEnvironment();
    final database = await Database.connect(config);
    await database.runMigrations();
    final jwtService = JwtService(config);
    final authService = AuthService(database: database, config: config);
    final weatherService = WeatherService(config: config);
    final zoneService = ZoneService(database: database, config: config);
    final zoneIngestService = ZoneIngestService(
      database: database,
      zoneService: zoneService,
    );
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
      zoneService: zoneService,
      zoneIngestService: zoneIngestService,
      postService: postService,
      messagingService: messagingService,
      notificationService: notificationService,
    );
    return _instance!;
  }

  static Future<void> dispose() async {
    await _instance?.database.close();
    _instance = null;
  }
}
