import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/wind_map_config.dart';

/// Slippy-map tile indices covering [bounds] at [zoom].
List<TileCoordinates> visibleWindTiles({
  required MapVisibleBounds bounds,
  required double zoom,
}) {
  // Match flutter_map [TileLayer] native zoom (`zoom.round()`).
  var z = zoom.round().clamp(0, WindMapConfig.windMaxZoom);
  var tiles = _tilesForBounds(bounds, z);
  // Coarser grid when the viewport spans many tiles (arrow fetch is heavy).
  while (tiles.length > 16 && z > 4) {
    z--;
    tiles = _tilesForBounds(bounds, z);
  }
  return tiles;
}

/// Coarser zoom than the map for u/v fetches (fewer HTTP / decode calls).
int windArrowDataZoom(double viewZoom) {
  final viewZ = viewZoom.round().clamp(0, WindMapConfig.windMaxZoom);
  if (viewZ <= 5) return viewZ;
  return math.max(4, viewZ - 3);
}

/// Tiles to load for direction arrows (capped for latency).
List<TileCoordinates> visibleWindArrowTiles({
  required MapVisibleBounds bounds,
  required double viewZoom,
}) {
  var z = windArrowDataZoom(viewZoom);
  var tiles = _tilesForBounds(bounds, z);
  while (tiles.length > 6 && z > 4) {
    z--;
    tiles = _tilesForBounds(bounds, z);
  }
  return tiles;
}

List<TileCoordinates> _tilesForBounds(MapVisibleBounds bounds, int z) {
  final sw = bounds.southWest;
  final ne = bounds.northEast;
  final xMin = _lonToTileX(sw.longitude, z);
  final xMax = _lonToTileX(ne.longitude, z);
  final yMin = _latToTileY(ne.latitude, z);
  final yMax = _latToTileY(sw.latitude, z);
  final tiles = <TileCoordinates>[];
  for (var x = xMin; x <= xMax; x++) {
    for (var y = yMin; y <= yMax; y++) {
      tiles.add(TileCoordinates(x, y, z));
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
