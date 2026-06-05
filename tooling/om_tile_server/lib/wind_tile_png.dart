import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:om_smoke/om/dwd_icon_grid.dart';
import 'package:om_tile_server/wind_color_scale.dart';

Uint8List encodeWindTilePng({
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
    lons[i] = nx / scale * 360 - 180;
  }

  // Write directly to a raw RGBA buffer — avoids img.Image.setPixelRgba
  // overhead (bounds checks, pixel-object indirection) for each of the
  // 65 536 pixels.
  final pixels = Uint8List(tileSize * tileSize * 4);
  for (var row = 0; row < tileSize; row++) {
    final lat = lats[row];
    for (var col = 0; col < tileSize; col++) {
      final gust = grid.valueAt(values, lat, lons[col]);
      WindColorScale.writePixel(pixels, (row * tileSize + col) * 4, gust);
    }
  }

  return rgbaToPng(pixels, tileSize: tileSize);
}

/// Encodes a raw RGBA buffer produced by [encodeWindTilePng] or the GPU path
/// into a PNG with fast (level 1) compression.
Uint8List rgbaToPng(Uint8List rgba, {int tileSize = 256}) {
  // Compression level 1 (fast): perceptually identical for noisy wind
  // rasters, roughly 2–3× faster than the default level 6.
  return img.encodePng(
    img.Image.fromBytes(
      width: tileSize,
      height: tileSize,
      bytes: rgba.buffer,
      numChannels: 4,
    ),
    level: 1,
  );
}
