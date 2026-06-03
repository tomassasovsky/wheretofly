import 'dart:io';

/// Runtime configuration loaded from environment variables.
class AppConfig {
  /// Creates config from explicit values (used in tests and fromEnvironment).
  const AppConfig({
    required this.databaseUrl,
    required this.redisUrl,
    required this.jwtSecret,
    required this.openAipApiKey,
    required this.photonBaseUrl,
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

  /// Loads configuration from process environment with dev-friendly defaults.
  factory AppConfig.fromEnvironment() {
    return AppConfig(
      databaseUrl:
          Platform.environment['DATABASE_URL'] ??
          'postgresql://dondevolar:dondevolar@localhost:5432/dondevolar',
      redisUrl: Platform.environment['REDIS_URL'] ?? 'redis://localhost:6379',
      jwtSecret: Platform.environment['JWT_SECRET'] ?? 'dev-secret-change-me',
      openAipApiKey: Platform.environment['OPENAIP_API_KEY'] ?? '',
      photonBaseUrl:
          Platform.environment['PHOTON_BASE_URL'] ?? 'http://localhost:2322',
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

  /// PostgreSQL connection URI.
  final String databaseUrl;

  /// Redis connection URI for caching and queues.
  final String redisUrl;

  /// Secret used to sign JWT access tokens.
  final String jwtSecret;

  /// OpenAIP airspace API key (empty skips live airspace during zone ingest).
  final String openAipApiKey;

  /// Base URL for the self-hosted Photon geocoder (no trailing slash).
  final String photonBaseUrl;

  /// MinIO/S3-compatible object storage host.
  final String minioEndpoint;

  /// MinIO access key.
  final String minioAccessKey;

  /// MinIO secret key.
  final String minioSecretKey;

  /// Default bucket for uploaded media.
  final String minioBucket;

  /// Google OAuth client ID for social sign-in.
  final String googleClientId;

  /// Apple OAuth client ID for social sign-in.
  final String appleClientId;

  /// Filesystem path to the published zone GeoJSON feed.
  final String zoneFeedPath;

  /// HTTP port the Dart Frog server binds to.
  final int port;

  /// Lifetime of issued access tokens.
  final Duration accessTokenTtl;

  /// Lifetime of refresh-token sessions.
  final Duration refreshTokenTtl;

  /// Current API version string exposed to clients.
  static const version = '1.0.0';

  /// Minimum supported client app version.
  static const minClientVersion = '1.0.0';
}
