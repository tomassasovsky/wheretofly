import 'dart:math' as math;
import 'dart:typed_data';

import 'package:where_to_fly/map/wind/om/dwd_icon_grid.dart';
import 'package:where_to_fly/map/wind/om/wind_color_scale.dart';

/// Builds a 256×256 RGBA tile for gust values (testable without [dart:ui]).
Uint8List buildWindTileRgba({
  required Float32List values,
  required DwdIconTileRead tileRead,
  int tileSize = 256,
}) {
  final grid = tileRead.toGrid();

  // Hoist pow(2, z): the original called it 131 072 times per tile (once per
  // pixel in both tile2lat and tile2lon). Compute it once here instead.
  final scale = math.pow(2, tileRead.z).toDouble();

  // Precompute lat per row and lon per column — tileSize iterations instead
  // of tileSize² lat computations and tileSize² lon computations.
  final lats = Float64List(tileSize);
  final lons = Float64List(tileSize);
  for (var i = 0; i < tileSize; i++) {
    // tile2lat inlined with precomputed scale.
    final ny = tileRead.y + (i + 0.5) / tileSize;
    final n = math.pi - (2 * math.pi * ny) / scale;
    lats[i] = math.atan(0.5 * (math.exp(n) - math.exp(-n))) * 180 / math.pi;
    // tile2lon inlined with precomputed scale.
    final nx = tileRead.x + (i + 0.5) / tileSize;
    lons[i] = ((nx / scale * 360 + 360) % 360) - 180;
  }

  final rgba = Uint8List(tileSize * tileSize * 4);
  for (var row = 0; row < tileSize; row++) {
    final lat = lats[row];
    for (var col = 0; col < tileSize; col++) {
      final gust = grid.valueAt(values, lat, lons[col]);
      WindColorScale.writePixel(rgba, (row * tileSize + col) * 4, gust);
    }
  }
  return rgba;
}
