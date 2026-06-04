import 'package:backend/services/password_hasher.dart';
import 'package:test/test.dart';

void main() {
  group('PasswordHasher', () {
    const hasher = PasswordHasher();

    test('verify returns true for the correct password', () {
      final hash = hasher.hash('correct horse battery');
      expect(hasher.verify('correct horse battery', hash), isTrue);
    });

    test('verify returns false for an incorrect password', () {
      final hash = hasher.hash('correct horse battery');
      expect(hasher.verify('wrong password', hash), isFalse);
    });

    test(
      'hashing the same password twice yields different (salted) hashes',
      () {
        final a = hasher.hash('same-password');
        final b = hasher.hash('same-password');
        expect(a, isNot(equals(b)));
        expect(hasher.verify('same-password', a), isTrue);
        expect(hasher.verify('same-password', b), isTrue);
      },
    );
  });
}
