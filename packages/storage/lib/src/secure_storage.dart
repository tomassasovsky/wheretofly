import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Data client: an encrypted key/value store backed by the platform Keychain
/// (iOS/macOS), Keystore-backed EncryptedSharedPreferences (Android), or the
/// equivalent secure backend on other platforms.
///
/// Use this for sensitive values (e.g. auth tokens). Non-sensitive settings
/// belong in `Storage` instead.
class SecureStorage {
  SecureStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);
}
