import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Builds wind-map HTML with an HTTPS document origin so the WebView can
/// fetch Open-Meteo tiles (local `loadFlutterAsset` origins often cannot).
///
/// MapLibre and weather-map-layer are inlined from [assets/wind_map/] so the
/// shell does not depend on unpkg or other CDNs.
abstract final class WindMapHtmlLoader {
  /// Document base URL — must be HTTPS, not `flutter://` or `file://`.
  static const documentBaseUrl = 'https://map-assets.open-meteo.com/';

  static Future<String>? _cachedHtml;

  /// Builds the heavy HTML bundle once during app startup.
  static Future<void> prewarm() => _buildHtml();

  static Future<void> load(WebViewController controller) async {
    _cachedHtml ??= _buildHtml();
    final html = await _cachedHtml!;
    await controller.loadHtmlString(html, baseUrl: documentBaseUrl);
  }

  static Future<String> _buildHtml() async {
    final results = await Future.wait([
      rootBundle.loadString('assets/wind_map/maplibre-gl.css'),
      rootBundle.loadString('assets/wind_map/maplibre-gl.js'),
      rootBundle.loadString('assets/wind_map/weather-map-layer.js'),
      rootBundle.loadString('assets/wind_map/wind_map.js'),
    ]);
    final css = _escapeForHtml(results[0]);
    final maplibreJs = _escapeScript(results[1]);
    final weatherJs = _escapeScript(results[2]);
    final windMapJs = _escapeScript(results[3]);

    return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"
    />
    <style>$css</style>
    <style>
      html, body, #map {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        overflow: hidden;
        background: transparent;
      }
      #map {
        position: absolute;
        inset: 0;
        pointer-events: none;
      }
    </style>
  </head>
  <body>
    <div id="map"></div>
    <script>$maplibreJs</script>
    <script>$weatherJs</script>
    <script>$windMapJs</script>
  </body>
</html>
''';
  }

  static String _escapeScript(String source) =>
      source.replaceAll('</script>', r'<\/script>');

  static String _escapeForHtml(String source) =>
      source.replaceAll('</style>', r'<\/style>');
}
