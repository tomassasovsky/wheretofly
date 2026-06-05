// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:backend/services/wind_tile_service.dart';

/// Smoke-test Argentina viewport tiles at low zoom levels.
///
/// `dart run tool/smoke_wind_tiles_low_zoom.dart` from backend/
Future<void> main() async {
  const south = -55.0;
  const north = -22.0;
  const west = -73.0;
  const east = -53.0;

  final service = WindTileService(
    wasmPath: '../assets/om/om_reader_wasm.wasm',
  );

  for (final z in [3, 4, 5]) {
    final tiles = _tilesForBounds(
      south: south,
      north: north,
      west: west,
      east: east,
      z: z,
    );
    print('z=$z tiles=${tiles.length}');
    for (final (x, y) in tiles) {
      try {
        final png = await service.gustPng(z: z, x: x, y: y);
        print('  ok $z/$x/$y ${png.length} bytes');
        if (png.length < 1000) {
          throw StateError('PNG too small');
        }
      } on Object catch (e) {
        print('  FAIL $z/$x/$y: $e');
      }
    }
  }
}

List<(int x, int y)> _tilesForBounds({
  required double south,
  required double north,
  required double west,
  required double east,
  required int z,
}) {
  final xMin = _lonToTileX(west, z);
  final xMax = _lonToTileX(east, z);
  final yMin = _latToTileY(north, z);
  final yMax = _latToTileY(south, z);
  final tiles = <(int, int)>[];
  for (var x = xMin; x <= xMax; x++) {
    for (var y = yMin; y <= yMax; y++) {
      tiles.add((x, y));
    }
  }
  return tiles;
}

int _lonToTileX(double lon, int z) {
  final n = 1 << z;
  return ((lon + 180) / 360 * n).floor().clamp(0, n - 1);
}

int _latToTileY(double lat, int z) {
  final latRad = lat * math.pi / 180;
  final n = 1 << z;
  final y =
      (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n;
  return y.floor().clamp(0, n - 1);
}
