import 'package:backend/config/app_config.dart';
import 'package:test/test.dart';

void main() {
  group('AppConfig', () {
    test('prefers POSTGRES_HOST over DATABASE_URL for connections', () {
      const config = AppConfig(
        databaseUrl: 'postgresql://ignored:ignored@wrong:5432/ignored',
        postgresHost: 'postgres',
        postgresPassword: 'from-env',
        redisUrl: '',
        jwtSecret: 'jwt',
        openAipApiKey: '',
        photonBaseUrl: '',
        minioEndpoint: '',
        minioAccessKey: '',
        minioSecretKey: '',
        minioBucket: '',
        googleClientId: '',
        appleClientId: '',
        zoneFeedPath: '/app/data/zones.geojson',
      );

      expect(config.postgresHost, 'postgres');
      expect(config.postgresPassword, 'from-env');
      expect(config.databaseUrl, isEmpty);
    });
  });
}
