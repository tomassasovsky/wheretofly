import 'dart:convert';

import 'package:where_to_fly/map/wind_map_config.dart';

/// Messages posted from the wind map WebView to Flutter.
enum WindMapMessageType {
  /// Basemap is interactive; wind tiles may still be streaming in.
  mapReady,

  /// Wind overlay failed; basemap remains usable.
  windError,

  /// Fatal — shell (HTML/MapLibre/style) failed.
  error,
  unknown;

  static WindMapMessageType parse(String? value) => switch (value) {
        'mapReady' => WindMapMessageType.mapReady,
        'windError' => WindMapMessageType.windError,
        'error' => WindMapMessageType.error,
        _ => WindMapMessageType.unknown,
      };
}

class WindMapBridgeMessage {
  const WindMapBridgeMessage({
    required this.type,
    this.message = '',
  });

  factory WindMapBridgeMessage.fromJson(Map<String, dynamic> json) {
    return WindMapBridgeMessage(
      type: WindMapMessageType.parse(json['type'] as String?),
      message: json['message'] as String? ?? '',
    );
  }

  factory WindMapBridgeMessage.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return WindMapBridgeMessage.fromJson(json);
  }

  final WindMapMessageType type;
  final String message;
}

/// JavaScript sent to the wind map WebView.
abstract final class WindMapBridgeCommands {
  static String init({
    required String styleUrl,
    required double lat,
    required double lon,
    required double zoom,
    required int shellTimeoutMs,
    String? omSourceUrl,
    bool overlayOnly = false,
    String model = WindMapConfig.model,
    String variable = WindMapConfig.variable,
    String timeStep = WindMapConfig.timeStep,
  }) {
    final style = _escapeJs(styleUrl);
    final omUrl =
        omSourceUrl != null ? "omSourceUrl: '${_escapeJs(omSourceUrl)}'," : '';
    return '''
(function() {
  if (!window.WindMapApp) {
    if (window.WindMap) {
      window.WindMap.postMessage(JSON.stringify({
        type: 'error',
        message: 'scripts_not_loaded',
      }));
    }
    return;
  }
  window.WindMapApp.init({
    styleUrl: '$style',
    overlayOnly: $overlayOnly,
    lat: $lat,
    lon: $lon,
    zoom: $zoom,
    shellTimeoutMs: $shellTimeoutMs,
    model: '${_escapeJs(model)}',
    variable: '${_escapeJs(variable)}',
    timeStep: '${_escapeJs(timeStep)}',
    $omUrl
  });
})();''';
  }

  static String setCenter({
    required double lat,
    required double lon,
    required double zoom,
    bool instant = false,
  }) =>
      'window.WindMapApp?.setCenter($lat, $lon, $zoom, $instant);';

  static String zoomBy(double delta) => 'window.WindMapApp?.zoomBy($delta);';

  static String _escapeJs(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
}
