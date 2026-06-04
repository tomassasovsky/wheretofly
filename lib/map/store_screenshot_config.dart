import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:settings_repository/settings_repository.dart' show SettingsRepository;

/// QA flags for automated store listing screenshots (integration_test).
abstract final class StoreScreenshotConfig {
  /// Set via `--dart-define=STORE_SCREENSHOT_AUTO_SELECT=true` during capture.
  static const captureMode = bool.fromEnvironment(
    'STORE_SCREENSHOT_AUTO_SELECT',
  );

  /// `en` or `es` — forces [SettingsRepository] locale during capture.
  static const localeCode = String.fromEnvironment(
    'STORE_SCREENSHOT_LOCALE',
  );

  /// Pre-select a Buenos Aires point so the verdict card is visible without
  /// tapping the map in integration tests.
  static bool get autoSelectVerdict => captureMode;

  static const verdictPoint = LatLng(-34.608, -58.37);

  /// Map tile / geocoding failures while the simulator has network hiccups.
  static bool isBenignFlutterError(FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    final library = details.library ?? '';
    return library == 'image resource service' ||
        message.contains('ClientException') ||
        message.contains('HTTP request failed') ||
        message.contains('ImageCodec') ||
        message.contains('NetworkImageLoadException') ||
        message.contains('Multiple exceptions') ||
        message.contains('SocketException') ||
        message.contains('Failed host lookup');
  }
}
