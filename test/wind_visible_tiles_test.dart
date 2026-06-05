import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/map_initializer.dart';
import 'package:where_to_fly/map/map_layout.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/map_zoom_limits.dart';
import 'package:where_to_fly/map/wind/om/wind_visible_tiles.dart';

void main() {
  test('visibleWindTiles uses slippy (x, y, z) not swapped zoom', () {
    const bounds = MapVisibleBounds(
      southWest: LatLng(-40, -65),
      northEast: LatLng(-35, -60),
    );
    final tiles = visibleWindTiles(bounds: bounds, zoom: 7);
    expect(tiles, isNotEmpty);
    for (final t in tiles) {
      expect(t.z, 7, reason: 'zoom must be 7, not tile x index');
      expect(t.x, inInclusiveRange(0, 127));
      expect(t.y, inInclusiveRange(0, 127));
    }
  });

  test('windArrowDataZoom is coarser than map at high zoom', () {
    expect(windArrowDataZoom(7), 4);
    expect(windArrowDataZoom(5), 5);
  });

  test('visibleWindTiles covers Argentina at phone min zoom', () {
    const size = Point<double>(390, 844);
    const padding = EdgeInsets.only(
      top: MapLayout.topOverlayInset,
      bottom: 116,
    );
    final minZoom = MapZoomLimits.minZoomFittingBoundsHeight(
      mapSize: size,
      bounds: MapInitializer.argentinaBounds,
      padding: padding,
    );
    final bounds = MapVisibleBounds(
      southWest: MapInitializer.argentinaBounds.southWest,
      northEast: MapInitializer.argentinaBounds.northEast,
    );
    final tiles = visibleWindTiles(bounds: bounds, zoom: minZoom);
    expect(tiles, isNotEmpty);
    expect(tiles.length, lessThanOrEqualTo(16));
    for (final t in tiles) {
      expect(t.z, greaterThanOrEqualTo(3));
      expect(t.z, lessThanOrEqualTo(minZoom.round()));
    }
  });

  test('visibleWindArrowTiles caps tile count', () {
    const bounds = MapVisibleBounds(
      southWest: LatLng(-50, -75),
      northEast: LatLng(-30, -55),
    );
    final tiles = visibleWindArrowTiles(bounds: bounds, viewZoom: 8);
    expect(tiles.length, lessThanOrEqualTo(6));
  });
}
