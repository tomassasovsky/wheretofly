import 'dart:math' as math show max;
import 'dart:math' show Point;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Computes zoom limits from viewport size and geographic bounds.
abstract final class MapZoomLimits {
  /// Fallback until [FlutterMap] has laid out with a real size.
  static const fallbackMinZoom = 3.0;

  /// Zoom level where [bounds] north–south span fills the viewport height.
  ///
  /// Wider than the screen is allowed; users cannot zoom out further
  /// vertically.
  static double minZoomFittingBoundsHeight({
    required Point<double> mapSize,
    required LatLngBounds bounds,
    EdgeInsets padding = EdgeInsets.zero,
    Crs crs = const Epsg3857(),
  }) {
    final height = math.max(0, mapSize.y - padding.vertical);
    if (height <= 0) return fallbackMinZoom;

    final camera = MapCamera(
      crs: crs,
      center: bounds.center,
      zoom: 0,
      rotation: 0,
      nonRotatedSize: mapSize,
    );

    final boundsHeight = Bounds<double>(
      camera.project(bounds.southEast, camera.zoom),
      camera.project(bounds.northWest, camera.zoom),
    ).size.y;

    if (boundsHeight <= 0) return fallbackMinZoom;

    return camera.getScaleZoom(height / boundsHeight);
  }
}
