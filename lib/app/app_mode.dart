import 'package:flutter/foundation.dart';

/// Product scope toggles while features roll out incrementally.
abstract final class AppMode {
  /// When true, only the map is exposed; social tabs redirect to the map.
  static const mapOnly = true;

  /// Overrides [mapOnly] in tests that exercise the full app shell.
  @visibleForTesting
  static bool? mapOnlyOverride;

  /// Effective map-only flag (honors [mapOnlyOverride] in tests).
  static bool get isMapOnly => mapOnlyOverride ?? mapOnly;
}
