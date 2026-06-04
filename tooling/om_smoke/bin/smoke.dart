// ignore_for_file: avoid_print

import 'package:om_smoke/om/dwd_icon_grid.dart';
import 'package:om_smoke/om/om_file_reader.dart';
import 'package:om_smoke/om/om_http_backend.dart';
import 'package:om_smoke/om/om_spatial_url.dart';
import 'package:om_smoke/om/om_wasm_module.dart';
import 'package:om_smoke/om/wasm_run_cli.dart';
import 'package:om_smoke/om/wind_tile_math.dart';
import 'package:wasm_run/wasm_run.dart';

const _model = 'dwd_icon';
const _variable = 'wind_gusts_10m';
const _timeStep = 'current_time_1H';

Future<void> main(List<String> args) async {
  final repoRoot = args.isNotEmpty ? args[0] : '../../';
  await ensureWasmRunCliLibrary();
  final features = await wasmRuntimeFeatures();
  final wasmFile = args.length > 1
      ? args[1]
      : features.supportedFeatures.simd
          ? '$repoRoot/assets/om/om_reader_wasm.wasm'
          : '$repoRoot/assets/om/om_reader_wasm_wasmi.wasm';
  print('runtime=${features.name} simd=${features.supportedFeatures.simd}');
  print('wasm=$wasmFile');

  await OmWasmModule.ensureInitialized(
    wasmPath: wasmFile,
    forceWasmi: wasmFile.contains('wasmi'),
  );
  final omUrl = await OmSpatialUrlResolver().resolveOmFileUrl(
    
  );
  print('om url: $omUrl');

  final root = await OmFileReader.open(
    Uri.parse(omUrl),
    backend: OmHttpBackend(),
  );
  final gust = await root.childByName(_variable);
  root.dispose();
  print('dims: ${gust.getDimensions()} name: ${gust.getName()}');

  const z = 5;
  const x = 8;
  const y = 12;
  final tileRead = DwdIconTileRead.forTile(z, x, y);
  print('tile $z/$x/$y read: $tileRead');

  final values = await DwdIconTileRead.readValues(gust.readFloat32, tileRead);
  gust.dispose();

  var finite = 0;
  var max = double.negativeInfinity;
  var min = double.infinity;
  for (final v in values) {
    if (v.isFinite) {
      finite++;
      if (v > max) max = v;
      if (v < min) min = v;
    }
  }
  print('decoded ${values.length} floats, finite=$finite min=$min max=$max');

  final grid = tileRead.toGrid();
  final centerLat = tile2lat(y + 0.5, z);
  final centerLon = tile2lon(x + 0.5, z);
  final centerGust = grid.valueAt(values, centerLat, centerLon);
  print('center gust at tile center ($centerLat, $centerLon): $centerGust');

  if (finite < values.length ~/ 10) {
    throw StateError('too few finite values — decode or grid ranges broken');
  }
  if (!centerGust.isFinite || centerGust < 0 || centerGust >= 80) {
    throw StateError('center sample not a plausible gust: $centerGust');
  }
  print('OK');
}
