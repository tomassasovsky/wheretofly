import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/wind/om/dwd_icon_grid.dart';
import 'package:where_to_fly/map/wind/om/wind_tile_rgba.dart';

void main() {
  test('buildWindTileRgba produces visible pixels for finite gust field', () {
    final tileRead = DwdIconTileRead.forTile(5, 8, 12);
    final values = Float32List(
      tileRead.totalNx * (tileRead.yRange.end - tileRead.yRange.start),
    );
    for (var i = 0; i < values.length; i++) {
      values[i] = 8.0;
    }
    final rgba = buildWindTileRgba(values: values, tileRead: tileRead);
    var opaque = 0;
    for (var i = 3; i < rgba.length; i += 4) {
      if (rgba[i] > 0) opaque++;
    }
    expect(opaque, greaterThan(1000));
  });
}
