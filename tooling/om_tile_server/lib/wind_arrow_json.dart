import 'dart:convert';
import 'dart:typed_data';

import 'package:om_smoke/om/dwd_icon_grid.dart';
import 'package:om_smoke/om/om_file_reader.dart';
import 'package:om_smoke/om/om_http_backend.dart';
import 'package:om_smoke/om/wind_tile_math.dart';

/// Grid subsample step by slippy zoom (keep in sync with app `arrowStepPxForZoom`).
int _arrowStepPxForZoom(int z) {
  if (z <= 4) return 64;
  if (z <= 6) return 48;
  if (z <= 8) return 32;
  return 16;
}

/// Sparse u/v samples for `/<z>/<x>/<y>.json` (matches app subsample step).
String encodeWindArrowJson({
  required Float32List u,
  required Float32List v,
  required DwdIconTileRead tileRead,
  double minSpeedMs = 0.5,
}) {
  final grid = tileRead.toGrid();
  final z = tileRead.z;
  final stepPx = _arrowStepPxForZoom(z);
  final x = tileRead.x;
  final y = tileRead.y;
  final rows = <Map<String, double>>[];

  for (var i = 0; i < 256; i += stepPx) {
    final lat = tile2lat(y + (i + 0.5) / 256, z);
    for (var j = 0; j < 256; j += stepPx) {
      final lon = tile2lon(x + (j + 0.5) / 256, z);
      final uVal = grid.valueAt(u, lat, lon);
      final vVal = grid.valueAt(v, lat, lon);
      if (!uVal.isFinite || !vVal.isFinite) continue;
      final speed = uVal * uVal + vVal * vVal;
      if (speed < minSpeedMs * minSpeedMs) continue;
      rows.add({'lat': lat, 'lon': lon, 'u': uVal, 'v': vVal});
    }
  }
  return jsonEncode(rows);
}

/// Opens u, v, and gust readers from one spatial `.om` file.
Future<({OmFileReader u, OmFileReader v, OmFileReader gust})> openWindReaders(
  Uri omUrl,
  OmHttpBackend backend,
) async {
  final root = await OmFileReader.open(omUrl, backend: backend);
  final u = await root.childByName('wind_u_component_10m');
  final v = await root.childByName('wind_v_component_10m');
  final gust = await root.childByName('wind_gusts_10m');
  root.dispose();
  return (u: u, v: v, gust: gust);
}
