import 'dart:io';

/// Runtime configuration loaded from environment variables.
class AppConfig {
  const AppConfig({
    required this.databaseUrl,
    required this.redisUrl,
    required this.jwtSecret,
    required this.openWeatherApiKey,
    required this.minioEndpoint,
    required this.minioAccessKey,
    required this.minioSecretKey,
    required this.minioBucket,
    required this.googleClientId,
    required this.appleClientId,
    required this.zoneFeedPath,
    this.port = 8080,
    this.accessTokenTtl = const Duration(minutes: 15),
    this.refreshTokenTtl = const Duration(days: 30),
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      databaseUrl:
          Platform.environment['DATABASE_URL'] ??
          'postgresql://dondevolar:dondevolar@localhost:5432/dondevolar',
      redisUrl: Platform.environment['REDIS_URL'] ?? 'redis://localhost:6379',
      jwtSecret: Platform.environment['JWT_SECRET'] ?? 'dev-secret-change-me',
      openWeatherApiKey: Platform.environment['OPENWEATHER_API_KEY'] ?? '',
      minioEndpoint: Platform.environment['MINIO_ENDPOINT'] ?? 'localhost:9000',
      minioAccessKey: Platform.environment['MINIO_ACCESS_KEY'] ?? 'minioadmin',
      minioSecretKey: Platform.environment['MINIO_SECRET_KEY'] ?? 'minioadmin',
      minioBucket: Platform.environment['MINIO_BUCKET'] ?? 'media',
      googleClientId: Platform.environment['GOOGLE_CLIENT_ID'] ?? '',
      appleClientId: Platform.environment['APPLE_CLIENT_ID'] ?? '',
      zoneFeedPath:
          Platform.environment['ZONE_FEED_PATH'] ?? 'data/zones.geojson',
      port: int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080,
    );
  }

  final String databaseUrl;
  final String redisUrl;
  final String jwtSecret;
  final String openWeatherApiKey;
  final String minioEndpoint;
  final String minioAccessKey;
  final String minioSecretKey;
  final String minioBucket;
  final String googleClientId;
  final String appleClientId;
  final String zoneFeedPath;
  final int port;
  final Duration accessTokenTtl;
  final Duration refreshTokenTtl;

  static const version = '1.0.0';
  static const minClientVersion = '1.0.0';
}
