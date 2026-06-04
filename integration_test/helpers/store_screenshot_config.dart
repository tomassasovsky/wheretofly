import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_repository/weather_repository.dart';

/// Store screenshot capture — integration_test only (flutter drive).
abstract final class StoreScreenshotConfig {
  /// `en` or `es` via `--dart-define=STORE_SCREENSHOT_LOCALE=…`.
  static const localeCode = String.fromEnvironment(
    'STORE_SCREENSHOT_LOCALE',
  );

  /// Buenos Aires — 02-map-verdict.
  static const verdictPoint = LatLng(-34.608, -58.37);

  static WeatherSnapshot weatherFixtureFor(LatLng point) {
    return WeatherSnapshot.fromJson({
      'location': {'lat': point.latitude, 'lon': point.longitude},
      'fetchedAt': DateTime.now().toUtc().toIso8601String(),
      'current': {'wind_speed': 2.3, 'wind_gust': 4.9},
      'hourly': <Map<String, dynamic>>[],
      'alerts': <Map<String, dynamic>>[],
      'advisory': {
        'level': 'good',
        'reasons': ['favorable'],
      },
    });
  }

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
