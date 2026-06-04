// ignore_for_file: avoid_print

import 'package:where_to_fly/map/wind/om/dwd_icon_grid.dart';
import 'package:where_to_fly/map/wind/om/om_file_reader.dart';
import 'package:where_to_fly/map/wind/om/om_http_backend.dart';
import 'package:where_to_fly/map/wind/om/om_spatial_url.dart';
import 'package:where_to_fly/map/wind/om/om_wasm_module.dart';
import 'package:where_to_fly/map/wind_map_config.dart';

Future<void> main() async {
  await OmWasmModule.ensureInitialized();
  final omUrl = await OmSpatialUrlResolver().resolveOmFileUrl(
    
  );
  print('om: $omUrl');
  final root = await OmFileReader.open(
    Uri.parse(omUrl),
    backend: OmHttpBackend(),
  );
  final gust = await root.childByName(WindMapConfig.variable);
  root.dispose();
  final ranges = DwdIconGrid.rangesForTile(5, 8, 12);
  final values = await gust.readFloat32(ranges);
  gust.dispose();
  var finite = 0;
  var max = double.negativeInfinity;
  for (final v in values) {
    if (v.isFinite) {
      finite++;
      if (v > max) max = v;
    }
  }
  print('values=${values.length} finite=$finite maxGust=$max');
  if (finite < 10) {
    throw StateError('decode produced almost no finite gust values');
  }
}
