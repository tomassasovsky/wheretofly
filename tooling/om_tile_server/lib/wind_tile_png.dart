import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:om_smoke/om/dwd_icon_grid.dart';
import 'package:om_smoke/om/wind_tile_math.dart';
import 'package:om_tile_server/wind_color_scale.dart';

Uint8List encodeWindTilePng({
  required Float32List values,
  required DwdIconTileRead tileRead,
  int tileSize = 256,
}) {
  final grid = tileRead.toGrid();
  final image = img.Image(width: tileSize, height: tileSize, numChannels: 4);
  for (var i = 0; i < tileSize; i++) {
    final lat = tile2lat(tileRead.y + (i + 0.5) / tileSize, tileRead.z);
    for (var j = 0; j < tileSize; j++) {
      final lon = tile2lon(tileRead.x + (j + 0.5) / tileSize, tileRead.z);
      final gust = grid.valueAt(values, lat, lon);
      if (!gust.isFinite) {
        image.setPixelRgba(j, i, 0, 0, 0, 0);
      } else {
        final (r, g, b, a) = WindColorScale.colorFor(gust);
        image.setPixelRgba(j, i, r, g, b, a);
      }
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
