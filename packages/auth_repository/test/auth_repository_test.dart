import 'package:auth_api_client/auth_api_client.dart';
import 'package:auth_repository/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

class _MockAuthApiClient extends Mock implements AuthApiClient {}

class _MockStorage extends Mock implements Storage {}

void main() {
  late AuthApiClient apiClient;
  late Storage storage;
  late AuthRepository repository;

  setUp(() {
    apiClient = _MockAuthApiClient();
    storage = _MockStorage();
    repository = AuthRepository(apiClient: apiClient, storage: storage);
  });

  test('login persists session', () async {
    const session = AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresInSeconds: 900,
    );
    when(
      () => apiClient.login(
          email: any(named: 'email'), password: any(named: 'password'),),
    ).thenAnswer((_) async => session);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    final result =
        await repository.login(email: 'a@b.com', password: 'password1');

    expect(result.accessToken, 'access');
    verify(() => storage.write('auth_session', any())).called(1);
  });
}
