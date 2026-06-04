import 'dart:convert';

import 'package:auth_api_client/auth_api_client.dart';
import 'package:storage/storage.dart';

/// Persists and refreshes auth sessions.
///
/// The session (including the refresh token) is stored in [SecureStorage] so
/// the long-lived credential is encrypted at rest rather than in plain
/// SharedPreferences.
class AuthRepository {
  AuthRepository({
    required AuthApiClient apiClient,
    required SecureStorage secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  static const _sessionKey = 'auth_session';

  final AuthApiClient _apiClient;
  final SecureStorage _secureStorage;

  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  }) async {
    final session = await _apiClient.signUp(
      email: email,
      password: password,
      handle: handle,
      displayName: displayName,
    );
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _apiClient.login(email: email, password: password);
    await _saveSession(session);
    return session;
  }

  Future<AuthSession?> currentSession() async {
    final raw = await _secureStorage.read(_sessionKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return AuthSession.fromJson(decoded);
  }

  Future<String?> accessToken() async {
    var session = await currentSession();
    if (session == null) return null;
    if (session.isAccessTokenExpired) {
      try {
        session = await refreshSession();
      } on Object {
        await logout();
        return null;
      }
    }
    return session.accessToken;
  }

  Future<void> logout() async {
    await _secureStorage.delete(_sessionKey);
  }

  Future<AuthSession> refreshSession() async {
    final session = await currentSession();
    if (session == null) {
      throw const AuthApiException('Not logged in', statusCode: 401);
    }
    final refreshed =
        await _apiClient.refresh(refreshToken: session.refreshToken);
    await _saveSession(refreshed);
    return refreshed;
  }

  /// Throws when the stored access token no longer maps to a server user.
  Future<void> validateStoredSession() async {
    final session = await currentSession();
    if (session == null) {
      throw const AuthApiException('Not logged in', statusCode: 401);
    }
    await _apiClient.validateSession(accessToken: session.accessToken);
  }

  Future<void> _saveSession(AuthSession session) async {
    await _secureStorage.write(_sessionKey, jsonEncode(session.toJson()));
  }
}
