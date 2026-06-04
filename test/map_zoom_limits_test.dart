import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/map_initializer.dart';
import 'package:where_to_fly/map/map_layout.dart';
import 'package:where_to_fly/map/map_zoom_limits.dart';

void main() {
  test('min zoom fits Argentina height on a phone-sized viewport', () {
    const size = Point<double>(390, 844);
    const padding = EdgeInsets.only(
      top: MapLayout.topOverlayInset,
      bottom: MapLayout.bottomOverlayInset,
    );

    final minZoom = MapZoomLimits.minZoomFittingBoundsHeight(
      mapSize: size,
      bounds: MapInitializer.argentinaBounds,
      padding: padding,
    );

    expect(minZoom, greaterThan(3));
    expect(minZoom, lessThan(7));
  });

  test('min zoom increases on shorter viewports', () {
    final tall = MapZoomLimits.minZoomFittingBoundsHeight(
      mapSize: const Point<double>(400, 900),
      bounds: MapInitializer.argentinaBounds,
    );
    final short = MapZoomLimits.minZoomFittingBoundsHeight(
      mapSize: const Point<double>(400, 500),
      bounds: MapInitializer.argentinaBounds,
    );

    expect(short, greaterThan(tall));
  });
}
