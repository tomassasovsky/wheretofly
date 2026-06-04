import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/wind/om/dwd_icon_grid.dart';
import 'package:where_to_fly/map/wind/om/om_dimension_range.dart';
import 'package:where_to_fly/map/wind/om/wind_tile_math.dart';

void main() {
  test('rangesForTile over Argentina uses positive grid indices', () {
    const z = 5;
    const x = 8;
    const y = 12;
    final ranges = DwdIconGrid.rangesForTile(z, x, y);
    expect(ranges, hasLength(2));
    expect(ranges[0].start, greaterThan(0));
    expect(ranges[1].start, greaterThan(0));
    expect(ranges[0].end, greaterThan(ranges[0].start));
    expect(ranges[1].end, greaterThan(ranges[1].start));

    final grid = DwdIconGrid.forRanges(ranges);
    final centerLat = tile2lat(y + 0.5, z);
    final centerLon = tile2lon(x + 0.5, z);
    expect(grid.bounds[0], lessThan(centerLon));
    expect(grid.bounds[2], greaterThan(centerLon));
    expect(grid.bounds[1], lessThan(centerLat));
    expect(grid.bounds[3], greaterThan(centerLat));
  });

  test('rangesForTile over antimeridian uses valid x segment', () {
    final read = DwdIconTileRead.forTile(2, 3, 2);
    expect(read.xSegments, hasLength(1));
    expect(read.xSegments.single.start, 2160);
    expect(read.xSegments.single.end, DwdIconGridData.nx);
    expect(read.totalNx, greaterThan(0));
  });

  test('tile edge pixels sample finite gust values', () {
    const z = 5;
    const x = 8;
    const y = 12;
    final tileRead = DwdIconTileRead.forTile(z, x, y);
    final grid = tileRead.toGrid();
    final values = Float32List(grid.nx * grid.ny);
    for (var i = 0; i < values.length; i++) {
      values[i] = 5.0;
    }
    final eastLon = tile2lon(x + 255.5 / 256, z);
    final southLat = tile2lat(y + 0.5 / 256, z);
    expect(grid.valueAt(values, southLat, eastLon).isFinite, isTrue);
  });

  test('coveringRanges matches lat/lon index from grid origin', () {
    final ranges = DwdIconGrid.forRanges([
      const OmDimensionRange(start: 0, end: DwdIconGridData.ny),
      const OmDimensionRange(start: 0, end: DwdIconGridData.nx),
    ]).coveringRanges(
      south: -40,
      west: -65,
      north: -38,
      east: -62,
    );
    expect(
      ranges[0].start,
      ((-40 - DwdIconGridData.latMin) / DwdIconGridData.dy).floor(),
    );
    expect(
      ranges[1].start,
      ((-65 - DwdIconGridData.lonMin) / DwdIconGridData.dx).floor(),
    );
  });
}
