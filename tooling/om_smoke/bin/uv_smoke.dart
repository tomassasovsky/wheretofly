// ignore_for_file: avoid_print

import 'package:om_smoke/om/dwd_icon_grid.dart';
import 'package:om_smoke/om/om_file_reader.dart';
import 'package:om_smoke/om/om_http_backend.dart';
import 'package:om_smoke/om/om_spatial_url.dart';
import 'package:om_smoke/om/om_wasm_module.dart';
import 'package:om_smoke/om/wasm_run_cli.dart';
import 'package:om_smoke/om/wind_tile_math.dart';

const _model = 'dwd_icon';
const _gust = 'wind_gusts_10m';
const _u = 'wind_u_component_10m';
const _v = 'wind_v_component_10m';
const _timeStep = 'current_time_1H';

Future<void> main(List<String> args) async {
  final repoRoot = args.isNotEmpty ? args[0] : '../../';
  await ensureWasmRunCliLibrary();
  await OmWasmModule.ensureInitialized(
    wasmPath: '$repoRoot/assets/om/om_reader_wasm.wasm',
  );

  final omUrl = await OmSpatialUrlResolver().resolveOmFileUrl(
    
  );
  print('om url: $omUrl');

  const z = 5;
  const x = 8;
  const y = 12;
  final tileRead = DwdIconTileRead.forTile(z, x, y);

  final root = await OmFileReader.open(
    Uri.parse(omUrl),
    backend: OmHttpBackend(),
  );
  final uReader = await root.childByName(_u);
  final vReader = await root.childByName(_v);
  final gustReader = await root.childByName(_gust);
  root.dispose();

  final u = await DwdIconTileRead.readValues(uReader.readFloat32, tileRead);
  final v = await DwdIconTileRead.readValues(vReader.readFloat32, tileRead);
  final gust =
      await DwdIconTileRead.readValues(gustReader.readFloat32, tileRead);
  uReader.dispose();
  vReader.dispose();
  gustReader.dispose();

  final grid = tileRead.toGrid();
  final centerLat = tile2lat(y + 0.5, z);
  final centerLon = tile2lon(x + 0.5, z);
  final uc = grid.valueAt(u, centerLat, centerLon);
  final vc = grid.valueAt(v, centerLat, centerLon);
  final gc = grid.valueAt(gust, centerLat, centerLon);

  print('center u=$uc v=$vc gust=$gc');
  print('u finite: ${u.where((e) => e.isFinite).length}/${u.length}');
  print('v finite: ${v.where((e) => e.isFinite).length}/${v.length}');

  if (!uc.isFinite || !vc.isFinite) {
    throw StateError('u/v not finite at tile center');
  }
  if (uc.abs() > 120 || vc.abs() > 120) {
    throw StateError('u/v out of plausible range at center');
  }
  print('OK');
}
