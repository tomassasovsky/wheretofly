import 'package:shared_preferences/shared_preferences.dart';

/// Data client: a thin, typed wrapper around [SharedPreferences].
///
/// The data layer is free of domain logic; it just reads and writes strings.
class Storage {
  Storage(this._prefs);

  final SharedPreferences _prefs;

  /// Creates a [Storage] backed by the default shared preferences.
  static Future<Storage> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return Storage(prefs);
  }

  String? read(String key) => _prefs.getString(key);

  Future<void> write(String key, String value) => _prefs.setString(key, value);

  Future<void> delete(String key) => _prefs.remove(key);
}
