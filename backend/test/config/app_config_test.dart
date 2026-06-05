import 'package:backend/config/app_config.dart';
import 'package:backend/db/postgres_endpoint.dart';
import 'package:test/test.dart';

void main() {
  group('AppConfig', () {
    test('postgresEndpointFor uses POSTGRES_HOST when host is set', () {
      const config = AppConfig(
        databaseUrl: 'postgresql://ignored:ignored@wrong:5432/ignored',
        postgresHost: 'postgres',
        postgresPassword: 'from-env',
        redisUrl: '',
        jwtSecret: 'jwt',
        openAipApiKey: '',
        photonBaseUrl: '',
        openMeteoHost: 'api.open-meteo.com',
        weatherCacheDuration: Duration(minutes: 30),
        minioEndpoint: '',
        minioAccessKey: '',
        minioSecretKey: '',
        minioBucket: '',
        googleClientId: '',
        appleClientId: '',
        zoneFeedPath: '/app/data/zones.geojson',
      );

      final endpoint = postgresEndpointFor(config);

      expect(endpoint.host, 'postgres');
      expect(endpoint.password, 'from-env');
      expect(endpoint.username, 'dondevolar');
    });
  });
}
