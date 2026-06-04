import 'package:auth_api_client/auth_api_client.dart';
import 'package:auth_repository/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

class _MockAuthApiClient extends Mock implements AuthApiClient {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late AuthApiClient apiClient;
  late SecureStorage secureStorage;
  late AuthRepository repository;

  setUp(() {
    apiClient = _MockAuthApiClient();
    secureStorage = _MockSecureStorage();
    repository = AuthRepository(
      apiClient: apiClient,
      secureStorage: secureStorage,
    );
  });

  test('login persists session', () async {
    const session = AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresInSeconds: 900,
    );
    when(
      () => apiClient.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => session);
    when(() => secureStorage.write(any(), any())).thenAnswer((_) async {});

    final result =
        await repository.login(email: 'a@b.com', password: 'password1');

    expect(result.accessToken, 'access');
    verify(() => secureStorage.write('auth_session', any())).called(1);
  });
}
