import 'dart:typed_data';

import 'package:where_to_fly/map/wind/om/dwd_icon_grid.dart';
import 'package:where_to_fly/map/wind/om/wind_color_scale.dart';
import 'package:where_to_fly/map/wind/om/wind_tile_math.dart';

/// Builds a 256×256 RGBA tile for gust values (testable without [dart:ui]).
Uint8List buildWindTileRgba({
  required Float32List values,
  required DwdIconTileRead tileRead,
  int tileSize = 256,
}) {
  final grid = tileRead.toGrid();
  final rgba = Uint8List(tileSize * tileSize * 4);
  for (var i = 0; i < tileSize; i++) {
    final lat = tile2lat(tileRead.y + (i + 0.5) / tileSize, tileRead.z);
    for (var j = 0; j < tileSize; j++) {
      final ind = j + i * tileSize;
      final lon = tile2lon(tileRead.x + (j + 0.5) / tileSize, tileRead.z);
      final gust = grid.valueAt(values, lat, lon);
      final color = gust.isFinite ? WindColorScale.colorFor(gust) : null;
      final base = ind * 4;
      if (color == null) {
        rgba[base] = 0;
        rgba[base + 1] = 0;
        rgba[base + 2] = 0;
        rgba[base + 3] = 0;
      } else {
        rgba[base] = (color.r * 255).round();
        rgba[base + 1] = (color.g * 255).round();
        rgba[base + 2] = (color.b * 255).round();
        rgba[base + 3] = (color.a * 255).round();
      }
    }
  }
  return rgba;
}
