import 'package:settings_repository/src/models/app_theme_mode.dart';
import 'package:storage/storage.dart';

/// Repository: persists user preferences on top of [Storage].
///
/// Stores primitive values only (no Flutter / domain enum leakage from other
/// repositories): the held permission as a string id, the language code, and
/// the theme mode.
class SettingsRepository {
  const SettingsRepository(this._storage);

  final Storage _storage;

  static const _permissionKey = 'permission_level';
  static const _modalityKey = 'flight_modality';
  static const _altitudeMinKey = 'flight_altitude_min_meters_agl';
  static const _altitudeMaxKey = 'flight_altitude_max_meters_agl';
  static const _altitudeLegacyKey = 'flight_altitude_meters_agl';
  static const _localeKey = 'locale';
  static const _themeModeKey = 'theme_mode';

  static const defaultFlightAltitudeMinMetersAgl = 0.0;

  /// Matches open-category default max (122 m AGL).
  static const defaultFlightAltitudeMaxMetersAgl = 122.0;

  /// The id of the last permission the user selected, or null if unset.
  String? get permissionId => _storage.read(_permissionKey);

  Future<void> setPermissionId(String id) => _storage.write(_permissionKey, id);

  /// The id of the last flight modality the user selected, or null if unset.
  String? get modalityId => _storage.read(_modalityKey);

  Future<void> setModalityId(String id) => _storage.write(_modalityKey, id);

  /// Planned flight altitude band (min/max m AGL).
  ({double min, double max}) get flightAltitudeRangeAgl {
    final maxRaw =
        _storage.read(_altitudeMaxKey) ?? _storage.read(_altitudeLegacyKey);
    final minRaw = _storage.read(_altitudeMinKey);

    final max = _parseAltitude(maxRaw) ?? defaultFlightAltitudeMaxMetersAgl;
    final min = _parseAltitude(minRaw) ?? defaultFlightAltitudeMinMetersAgl;
    if (min <= max) return (min: min, max: max);
    return (min: defaultFlightAltitudeMinMetersAgl, max: max);
  }

  Future<void> setFlightAltitudeRangeAgl({
    required double minMetersAgl,
    required double maxMetersAgl,
  }) async {
    await _storage.write(_altitudeMinKey, minMetersAgl.toString());
    await _storage.write(_altitudeMaxKey, maxMetersAgl.toString());
  }

  /// The persisted language code (`es` / `en`), or null to follow the device.
  String? get localeCode => _storage.read(_localeKey);

  Future<void> setLocaleCode(String? code) => code == null
      ? _storage.delete(_localeKey)
      : _storage.write(_localeKey, code);

  /// The persisted theme mode, defaulting to [AppThemeMode.system].
  AppThemeMode get themeMode =>
      AppThemeMode.fromName(_storage.read(_themeModeKey));

  Future<void> setThemeMode(AppThemeMode mode) =>
      _storage.write(_themeModeKey, mode.name);

  static double? _parseAltitude(String? raw) {
    if (raw == null) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }
}
