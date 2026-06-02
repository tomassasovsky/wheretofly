import 'package:backend/config/app_config.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Issues and verifies JWT access tokens.
class JwtService {
  JwtService(this._config);

  final AppConfig _config;

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

  JWT? verifyAccessToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_config.jwtSecret));
      if (jwt.payload['type'] != 'access') return null;
      return jwt;
    } on Object {
      return null;
    }
  }

  String? userIdFromToken(String token) {
    final jwt = verifyAccessToken(token);
    final sub = jwt?.payload['sub'];
    return sub is String ? sub : null;
  }
}
