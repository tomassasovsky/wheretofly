import 'package:backend/config/app_config.dart';
import 'package:backend/services/jwt_service.dart';
import 'package:test/test.dart';

void main() {
  group('JwtService', () {
    late JwtService jwtService;

    setUp(() {
      jwtService = JwtService(
        const AppConfig(
          databaseUrl: '',
          redisUrl: '',
          jwtSecret: 'test-secret',
          openWeatherApiKey: '',
          minioEndpoint: '',
          minioAccessKey: '',
          minioSecretKey: '',
          minioBucket: '',
          googleClientId: '',
          appleClientId: '',
          zoneFeedPath: '',
        ),
      );
    });

    test('issues and verifies access token', () {
      final token = jwtService.issueAccessToken(
        userId: 'user-1',
        handle: 'pilot',
      );
      final userId = jwtService.userIdFromToken(token);
      expect(userId, 'user-1');
    });

    test('rejects invalid token', () {
      expect(jwtService.userIdFromToken('invalid'), isNull);
    });
  });
}
