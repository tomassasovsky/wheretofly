import 'dart:convert';

/// Stored auth session tokens.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;

  /// Handle claim from the access token JWT payload.
  String? get handle {
    final payload = _decodePayload();
    return payload?['handle'] as String?;
  }

  /// User id (`sub`) from the access token JWT payload.
  String? get userId {
    final payload = _decodePayload();
    return payload?['sub'] as String?;
  }

  /// True when the access token is expired or about to expire.
  bool get isAccessTokenExpired {
    final payload = _decodePayload();
    final exp = payload?['exp'];
    if (exp is! num) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    return DateTime.now().isAfter(
      expiry.subtract(const Duration(seconds: 30)),
    );
  }

  Map<String, dynamic>? _decodePayload() {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      final padding = StringBuffer(payload);
      while (padding.length % 4 != 0) {
        padding.write('=');
      }
      payload = padding.toString();
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } on Object {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresInSeconds': expiresInSeconds,
      };
}
