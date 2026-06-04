// ignore_for_file: avoid_print

import 'package:om_smoke/om/dwd_icon_grid.dart';
import 'package:om_smoke/om/wind_tile_math.dart';

void main(List<String> args) {
  final tiles =
      args.isEmpty ? ['2/3/2', '5/8/12', '3/4/5', '2/0/0', '2/3/3'] : args;
  for (final spec in tiles) {
    final parts = spec.split('/');
    final z = int.parse(parts[0]);
    final x = int.parse(parts[1]);
    final y = int.parse(parts[2]);
    final read = DwdIconTileRead.forTile(z, x, y);
    final cells = (read.yRange.end - read.yRange.start) * read.totalNx;
    print(
      '$spec south=${tile2lat(y + 1, z)} north=${tile2lat(y.toDouble(), z)} '
      'west=${tile2lon(x.toDouble(), z)} east=${tile2lon(x + 1.0, z)}',
    );
    print(
      '  y=${read.yRange.start}..${read.yRange.end} '
      'xSegments=${read.xSegments} cells=$cells',
    );
  }
}
