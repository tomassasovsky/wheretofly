import 'package:backend/config/app_config.dart';
import 'package:backend/db/database.dart';
import 'package:backend/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockDatabase extends Mock implements Database {}

void main() {
  group('AuthService.signUp validation', () {
    late AuthService service;

    setUp(() {
      service = AuthService(
        database: _MockDatabase(),
        config: const AppConfig(
          databaseUrl: '',
          redisUrl: '',
          jwtSecret: 'test-secret',
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
          zoneFeedPath: '',
        ),
      );
    });

    test('rejects an invalid email before touching the database', () {
      expect(
        () => service.signUp(
          email: 'bad',
          password: 'password1',
          handle: 'pilot',
          displayName: 'Pilot',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Invalid email',
          ),
        ),
      );
    });

    test('rejects a short password', () {
      expect(
        () => service.signUp(
          email: 'a@b.com',
          password: 'short',
          handle: 'pilot',
          displayName: 'Pilot',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Password must be at least 8 characters',
          ),
        ),
      );
    });

    test('rejects a handle with illegal characters', () {
      expect(
        () => service.signUp(
          email: 'a@b.com',
          password: 'password1',
          handle: 'bad handle!',
          displayName: 'Pilot',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
