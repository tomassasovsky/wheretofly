import 'dart:async';
import 'dart:convert';

import 'package:auth_api_client/src/models/auth_session.dart';
import 'package:http/http.dart' as http;

/// Thrown when an auth API call fails.
class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode = 400});

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

/// Data client for backend auth endpoints.
class AuthApiClient {
  AuthApiClient({required this.baseUrl, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final Uri baseUrl;
  final http.Client _http;

  static const _timeout = Duration(seconds: 10);

  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  }) async {
    return _postAuth('/v1/auth/signup', {
      'email': email,
      'password': password,
      'handle': handle,
      'displayName': displayName,
    });
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return _postAuth('/v1/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<AuthSession> refresh({required String refreshToken}) async {
    return _postAuth('/v1/auth/refresh', {
      'refreshToken': refreshToken,
    });
  }

  /// Confirms the access token still maps to an existing server user.
  Future<void> validateSession({required String accessToken}) async {
    final uri = baseUrl.replace(path: '/v1/auth/session');
    http.Response response;
    try {
      response = await _http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(_timeout);
    } on TimeoutException {
      throw AuthApiException(
        'Request timed out reaching $uri',
        statusCode: 408,
      );
    } on http.ClientException catch (e) {
      throw AuthApiException(
        'Cannot reach server at $uri (${e.message})',
        statusCode: 503,
      );
    } catch (_) {
      throw AuthApiException(
        'Network error reaching $uri',
        statusCode: 503,
      );
    }
    if (response.statusCode >= 400) {
      throw AuthApiException('Unauthorized', statusCode: response.statusCode);
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    await _post('/v1/auth/password_reset', {'email': email});
  }

  Future<void> verifyEmail({required String token}) async {
    await _post('/v1/auth/verify_email', {'token': token});
  }

  Future<AuthSession> _postAuth(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _post(path, body);
    return AuthSession.fromJson(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = baseUrl.replace(path: path);
    http.Response response;
    try {
      response = await _http
          .post(
            uri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw AuthApiException(
        'Request timed out reaching $uri',
        statusCode: 408,
      );
    } on http.ClientException catch (e) {
      throw AuthApiException(
        'Cannot reach server at $uri (${e.message}). '
        'On a physical device use your Mac LAN IP, e.g. '
        'flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8080',
        statusCode: 503,
      );
    } catch (_) {
      throw AuthApiException(
        'Network error reaching $uri',
        statusCode: 503,
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      final snippet = response.body.trim();
      throw AuthApiException(
        snippet.isEmpty
            ? 'Invalid server response (${response.statusCode})'
            : snippet,
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 400) {
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'Request failed';
      throw AuthApiException(message, statusCode: response.statusCode);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const AuthApiException('Invalid response');
    }
    return decoded;
  }
}
