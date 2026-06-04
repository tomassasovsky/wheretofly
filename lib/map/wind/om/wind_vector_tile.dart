import 'dart:typed_data';

import 'package:where_to_fly/map/wind/om/dwd_icon_grid.dart';

/// Decoded u/v wind components for one map tile.
class WindVectorTile {
  const WindVectorTile({
    required this.tileRead,
    required this.u,
    required this.v,
  });

  final DwdIconTileRead tileRead;
  final Float32List u;
  final Float32List v;
}
