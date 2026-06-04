import 'dart:convert';

import 'package:auth_api_client/auth_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

/// Configurable fake that returns a queued response and records the request.
class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({
    this.statusCode = 200,
    this.body = '{}',
  });

  int statusCode;
  String body;
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('AuthApiClient', () {
    final baseUrl = Uri.parse('http://localhost:8080');

    test('login parses the session and posts to the login endpoint', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'accessToken': 'access',
          'refreshToken': 'refresh',
          'expiresInSeconds': 900,
        }),
      );
      final client = AuthApiClient(baseUrl: baseUrl, httpClient: fake);

      final session = await client.login(email: 'a@b.com', password: 'pw');

      expect(session.accessToken, 'access');
      expect(session.refreshToken, 'refresh');
      expect(session.expiresInSeconds, 900);
      expect(fake.lastRequest!.url.path, '/v1/auth/login');
    });

    test('signUp parses the session', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'accessToken': 'a',
          'refreshToken': 'r',
          'expiresInSeconds': 60,
        }),
      );
      final client = AuthApiClient(baseUrl: baseUrl, httpClient: fake);

      final session = await client.signUp(
        email: 'a@b.com',
        password: 'pw',
        handle: 'handle',
        displayName: 'Name',
      );

      expect(session.accessToken, 'a');
      expect(fake.lastRequest!.url.path, '/v1/auth/signup');
    });

    test('refresh posts the refresh token', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'accessToken': 'a2',
          'refreshToken': 'r2',
          'expiresInSeconds': 60,
        }),
      );
      final client = AuthApiClient(baseUrl: baseUrl, httpClient: fake);

      final session = await client.refresh(refreshToken: 'r1');

      expect(session.accessToken, 'a2');
      expect(fake.lastRequest!.url.path, '/v1/auth/refresh');
    });

    test('surfaces the server error message on a 4xx response', () async {
      final fake = _FakeHttpClient(
        statusCode: 401,
        body: jsonEncode({'error': 'Invalid credentials'}),
      );
      final client = AuthApiClient(baseUrl: baseUrl, httpClient: fake);

      await expectLater(
        client.login(email: 'a@b.com', password: 'bad'),
        throwsA(
          isA<AuthApiException>()
              .having((e) => e.message, 'message', 'Invalid credentials')
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('throws on a malformed (non-JSON) body', () async {
      final fake = _FakeHttpClient(statusCode: 500, body: '<html>oops</html>');
      final client = AuthApiClient(baseUrl: baseUrl, httpClient: fake);

      await expectLater(
        client.login(email: 'a@b.com', password: 'pw'),
        throwsA(
          isA<AuthApiException>()
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('validateSession completes on 200', () async {
      final fake = _FakeHttpClient();
      final client = AuthApiClient(baseUrl: baseUrl, httpClient: fake);

      await expectLater(
        client.validateSession(accessToken: 'token'),
        completes,
      );
      expect(fake.lastRequest!.url.path, '/v1/auth/session');
      expect(
        fake.lastRequest!.headers['Authorization'],
        'Bearer token',
      );
    });

    test('validateSession throws on 401', () async {
      final fake = _FakeHttpClient(statusCode: 401);
      final client = AuthApiClient(baseUrl: baseUrl, httpClient: fake);

      await expectLater(
        client.validateSession(accessToken: 'token'),
        throwsA(
          isA<AuthApiException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });
}
