import 'package:bcrypt/bcrypt.dart';

/// Password hashing utilities.
class PasswordHasher {
  const PasswordHasher();

  String hash(String password) => BCrypt.hashpw(password, BCrypt.gensalt());

  bool verify(String password, String hash) => BCrypt.checkpw(password, hash);
}
