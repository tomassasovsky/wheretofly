import 'package:bcrypt/bcrypt.dart';

/// Password hashing utilities.
class PasswordHasher {
  /// Default bcrypt hasher instance.
  const PasswordHasher();

  /// Returns a bcrypt hash for [password].
  String hash(String password) => BCrypt.hashpw(password, BCrypt.gensalt());

  /// Returns true when [password] matches the stored [hash].
  bool verify(String password, String hash) => BCrypt.checkpw(password, hash);
}
