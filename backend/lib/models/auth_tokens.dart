/// JWT access + refresh token pair returned on login/signup.
class AuthTokens {
  /// Creates a token pair for API responses.
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
  });

  /// Short-lived JWT sent on each authenticated request.
  final String accessToken;

  /// Opaque refresh token stored server-side as a hashed session.
  final String refreshToken;

  /// Access token lifetime in seconds.
  final int expiresInSeconds;

  /// Serializes tokens for JSON API responses.
  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresInSeconds': expiresInSeconds,
    'tokenType': 'Bearer',
  };
}
