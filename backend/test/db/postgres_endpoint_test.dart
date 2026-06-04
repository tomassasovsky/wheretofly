import 'package:backend/config/app_config.dart';
import 'package:backend/db/postgres_endpoint.dart';
import 'package:test/test.dart';

AppConfig _config({
  String databaseUrl = '',
  String? postgresHost,
  String? postgresPassword,
}) {
  return AppConfig(
    databaseUrl: databaseUrl,
    postgresHost: postgresHost,
    postgresPassword: postgresPassword,
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
    zoneFeedPath: '',
  );
}

void main() {
  group('postgresEndpointFor', () {
    test('uses POSTGRES_* fields without parsing a URI', () {
      const password = r'p@ss:word/not#safe';
      final endpoint = postgresEndpointFor(
        _config(
          postgresHost: 'postgres',
          postgresPassword: password,
        ),
      );

      expect(endpoint.host, 'postgres');
      expect(endpoint.port, 5432);
      expect(endpoint.database, 'dondevolar');
      expect(endpoint.username, 'dondevolar');
      expect(endpoint.password, password);
    });

    test('parses DATABASE_URL with URI-encoded password', () {
      const password = 'p@ss:word';
      final url =
          'postgresql://dondevolar:${Uri.encodeComponent(password)}@db.internal:5432/dondevolar';
      final endpoint = postgresEndpointFor(_config(databaseUrl: url));

      expect(endpoint.host, 'db.internal');
      expect(endpoint.password, password);
    });

    test('mis-parses DATABASE_URL when password contains raw @', () {
      final url = 'postgresql://dondevolar:p@ss@postgres:5432/dondevolar';
      final endpoint = postgresEndpointFor(_config(databaseUrl: url));

      expect(endpoint.password, isNot('p@ss'));
      expect(endpoint.host, isNot('postgres'));
    });
  });
}
