import 'dart:convert';

import 'package:backend/config/app_config.dart';
import 'package:backend/db/database.dart';
import 'package:backend/models/auth_tokens.dart';
import 'package:backend/models/user.dart';
import 'package:backend/services/jwt_service.dart';
import 'package:backend/services/password_hasher.dart';
import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

/// Thrown when auth operations fail with a client-facing message.
class AuthException implements Exception {
  /// Creates an auth error with optional HTTP [statusCode].
  const AuthException(this.message, {this.statusCode = 400});

  /// Human-readable error returned to the client.
  final String message;

  /// Suggested HTTP status for API responses.
  final int statusCode;

  @override
  String toString() => message;
}

/// Email/password auth, sessions, and account lifecycle.
class AuthService {
  /// Creates an auth service with optional test doubles.
  AuthService({
    required Database database,
    required AppConfig config,
    PasswordHasher? passwordHasher,
    JwtService? jwtService,
    Uuid? uuid,
  }) : _db = database,
       _config = config,
       _passwordHasher = passwordHasher ?? const PasswordHasher(),
       _jwt = jwtService ?? JwtService(config),
       _uuid = uuid ?? const Uuid();

  final Database _db;
  final AppConfig _config;
  final PasswordHasher _passwordHasher;
  final JwtService _jwt;
  final Uuid _uuid;

  /// Registers a new user and returns access + refresh tokens.
  Future<AuthTokens> signUp({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  }) async {
    _validateEmail(email);
    _validatePassword(password);
    _validateHandle(handle);

    final userId = _uuid.v4();
    final passwordHash = _passwordHasher.hash(password);
    final verificationToken = _uuid.v4();

    try {
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO users (id, email, password_hash, handle, display_name, email_verified_at)
          VALUES (@id, @email, @passwordHash, @handle, @displayName, NOW())
        '''),
        parameters: {
          'id': userId,
          'email': email.toLowerCase(),
          'passwordHash': passwordHash,
          'handle': handle.toLowerCase(),
          'displayName': displayName,
        },
      );
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO email_verification_tokens (token, user_id, expires_at)
          VALUES (@token, @userId, NOW() + INTERVAL '24 hours')
        '''),
        parameters: {'token': verificationToken, 'userId': userId},
      );
    } on ServerException catch (e) {
      if (e.message.contains('unique')) {
        throw const AuthException(
          'Email or handle already in use',
          statusCode: 409,
        );
      }
      rethrow;
    }

    return _issueTokens(userId: userId, handle: handle.toLowerCase());
  }

  /// Validates credentials and issues a new token pair.
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT id, handle, password_hash
        FROM users
        WHERE email = @email AND is_hidden = FALSE
      '''),
      parameters: {'email': email.toLowerCase()},
    );
    if (result.isEmpty) {
      throw const AuthException('Invalid credentials', statusCode: 401);
    }
    final row = result.first;
    final hash = row[2] as String?;
    if (hash == null || !_passwordHasher.verify(password, hash)) {
      throw const AuthException('Invalid credentials', statusCode: 401);
    }
    return _issueTokens(
      userId: row[0]! as String,
      handle: row[1]! as String,
    );
  }

  /// Rotates refresh token and returns a new access + refresh pair.
  Future<AuthTokens> refresh({required String refreshToken}) async {
    final hash = _hashRefreshToken(refreshToken);
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT s.user_id, u.handle
        FROM sessions s
        JOIN users u ON u.id = s.user_id
        WHERE s.refresh_token_hash = @hash
          AND s.expires_at > NOW()
          AND u.is_hidden = FALSE
      '''),
      parameters: {'hash': hash},
    );
    if (result.isEmpty) {
      throw const AuthException('Invalid refresh token', statusCode: 401);
    }
    final userId = result.first[0]! as String;
    final handle = result.first[1]! as String;
    await _db.connection.execute(
      Sql.named('DELETE FROM sessions WHERE refresh_token_hash = @hash'),
      parameters: {'hash': hash},
    );
    return _issueTokens(userId: userId, handle: handle);
  }

  /// Returns true when the user id from a JWT still exists in the database.
  Future<bool> userExists(String userId) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT 1 FROM users
        WHERE id = @userId AND is_hidden = FALSE
        LIMIT 1
      '''),
      parameters: {'userId': userId},
    );
    return result.isNotEmpty;
  }

  /// Marks a user's email as verified using a one-time token.
  Future<void> verifyEmail({required String token}) async {
    final result = await _db.connection.execute(
      Sql.named('''
        UPDATE users u
        SET email_verified_at = NOW(), updated_at = NOW()
        FROM email_verification_tokens t
        WHERE t.token = @token
          AND t.user_id = u.id
          AND t.expires_at > NOW()
        RETURNING u.id
      '''),
      parameters: {'token': token},
    );
    if (result.isEmpty) {
      throw const AuthException(
        'Invalid or expired verification token',
      );
    }
    await _db.connection.execute(
      Sql.named('DELETE FROM email_verification_tokens WHERE token = @token'),
      parameters: {'token': token},
    );
  }

  /// Creates a password-reset token when [email] matches a user.
  Future<void> requestPasswordReset({required String email}) async {
    final result = await _db.connection.execute(
      Sql.named('SELECT id FROM users WHERE email = @email'),
      parameters: {'email': email.toLowerCase()},
    );
    if (result.isEmpty) return;
    final userId = result.first[0]! as String;
    final token = _uuid.v4();
    await _db.connection.execute(
      Sql.named('DELETE FROM password_reset_tokens WHERE user_id = @userId'),
      parameters: {'userId': userId},
    );
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO password_reset_tokens (token, user_id, expires_at)
        VALUES (@token, @userId, NOW() + INTERVAL '1 hour')
      '''),
      parameters: {'token': token, 'userId': userId},
    );
    // In production, send email with token. Logged for self-hosted dev.
    // ignore: avoid_print
    print('Password reset token for $email: $token');
  }

  /// Sets a new password from a valid reset [token].
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    _validatePassword(newPassword);
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT user_id FROM password_reset_tokens
        WHERE token = @token AND expires_at > NOW()
      '''),
      parameters: {'token': token},
    );
    if (result.isEmpty) {
      throw const AuthException(
        'Invalid or expired reset token',
      );
    }
    final userId = result.first[0]! as String;
    final passwordHash = _passwordHasher.hash(newPassword);
    await _db.connection.execute(
      Sql.named('''
        UPDATE users SET password_hash = @hash, updated_at = NOW()
        WHERE id = @userId
      '''),
      parameters: {'hash': passwordHash, 'userId': userId},
    );
    await _db.connection.execute(
      Sql.named('DELETE FROM password_reset_tokens WHERE token = @token'),
      parameters: {'token': token},
    );
    await _db.connection.execute(
      Sql.named('DELETE FROM sessions WHERE user_id = @userId'),
      parameters: {'userId': userId},
    );
  }

  /// Loads a profile by primary key, or null when hidden/missing.
  Future<UserProfile?> getUserById(String userId) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT id, email, handle, display_name, bio, avatar_url,
               email_verified_at, follow_mode, created_at
        FROM users
        WHERE id = @id AND is_hidden = FALSE
      '''),
      parameters: {'id': userId},
    );
    if (result.isEmpty) return null;
    return UserProfile.fromRow(result.first);
  }

  /// Loads a profile by @handle, or null when hidden/missing.
  Future<UserProfile?> getUserByHandle(String handle) async {
    final result = await _db.connection.execute(
      Sql.named('''
        SELECT id, email, handle, display_name, bio, avatar_url,
               email_verified_at, follow_mode, created_at
        FROM users
        WHERE handle = @handle AND is_hidden = FALSE
      '''),
      parameters: {'handle': handle.toLowerCase()},
    );
    if (result.isEmpty) return null;
    return UserProfile.fromRow(result.first);
  }

  /// Permanently deletes the user and cascaded related rows.
  Future<void> deleteAccount(String userId) async {
    await _db.connection.execute(
      Sql.named('DELETE FROM users WHERE id = @id'),
      parameters: {'id': userId},
    );
  }

  Future<AuthTokens> _issueTokens({
    required String userId,
    required String handle,
  }) async {
    final refreshToken = _uuid.v4();
    final sessionId = _uuid.v4();
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO sessions (id, user_id, refresh_token_hash, expires_at)
        VALUES (@id, @userId, @hash, NOW() + @days * INTERVAL '1 day')
      '''),
      parameters: {
        'id': sessionId,
        'userId': userId,
        'hash': _hashRefreshToken(refreshToken),
        'days': _config.refreshTokenTtl.inDays,
      },
    );
    return AuthTokens(
      accessToken: _jwt.issueAccessToken(userId: userId, handle: handle),
      refreshToken: refreshToken,
      expiresInSeconds: _config.accessTokenTtl.inSeconds,
    );
  }

  String _hashRefreshToken(String token) {
    return sha256.convert(utf8.encode(token)).toString();
  }

  void _validateEmail(String email) {
    if (!email.contains('@') || email.length < 5) {
      throw const AuthException('Invalid email');
    }
  }

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw const AuthException('Password must be at least 8 characters');
    }
  }

  void _validateHandle(String handle) {
    final normalized = handle.toLowerCase();
    if (normalized.length < 3 || normalized.length > 30) {
      throw const AuthException('Handle must be 3–30 characters');
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(normalized)) {
      throw const AuthException(
        'Handle may only contain letters, numbers, and underscores',
      );
    }
  }
}
