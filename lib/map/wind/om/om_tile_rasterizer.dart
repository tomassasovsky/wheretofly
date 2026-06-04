import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:where_to_fly/map/wind/om/dwd_icon_grid.dart';
import 'package:where_to_fly/map/wind/om/wind_tile_rgba.dart';

/// Renders a 256×256 wind gust raster tile from a float grid subset.
Future<ui.Image> rasterizeWindTile({
  required Float32List values,
  required DwdIconTileRead tileRead,
  int tileSize = 256,
}) async {
  final rgba = buildWindTileRgba(
    values: values,
    tileRead: tileRead,
    tileSize: tileSize,
  );
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: tileSize,
    height: tileSize,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final frame = await codec.getNextFrame();
  buffer.dispose();
  descriptor.dispose();
  codec.dispose();
  return frame.image;
}
