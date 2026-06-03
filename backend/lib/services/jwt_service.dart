import 'package:backend/config/app_config.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Issues and verifies JWT access tokens.
class JwtService {
  /// Creates a service bound to application JWT signing settings.
  JwtService(this._config);

  final AppConfig _config;

  /// Signs a short-lived access token for [userId] and [handle].
  String issueAccessToken({
    required String userId,
    required String handle,
  }) {
    final jwt = JWT({
      'sub': userId,
      'handle': handle,
      'type': 'access',
    });
    return jwt.sign(
      SecretKey(_config.jwtSecret),
      expiresIn: _config.accessTokenTtl,
    );
  }

  /// Verifies [token] and returns the JWT when valid and typed as access.
  JWT? verifyAccessToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_config.jwtSecret));
      final payload = _readPayload(jwt);
      if (payload?['type'] != 'access') return null;
      return jwt;
    } on Object {
      return null;
    }
  }

  /// Extracts the subject user id from a valid access [token].
  String? userIdFromToken(String token) {
    final jwt = verifyAccessToken(token);
    final sub = _readPayload(jwt)?['sub'];
    return sub is String ? sub : null;
  }

  Map<String, dynamic>? _readPayload(JWT? jwt) {
    if (jwt == null) return null;
    final payload = jwt.payload;
    return payload is Map<String, dynamic> ? payload : null;
  }
}
