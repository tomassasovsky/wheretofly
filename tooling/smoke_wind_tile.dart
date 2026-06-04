import 'dart:developer' as dev;

import 'package:flutter_map/flutter_map.dart';
import 'package:wasm_run/wasm_run.dart';
import 'package:where_to_fly/map/wind/om/om_wasm_module.dart';
import 'package:where_to_fly/map/wind/om/open_meteo_wind_data.dart';

/// End-to-end: WASM init + one Open-Meteo tile over HTTP.
Future<void> main() async {
  final features = await wasmRuntimeFeatures();
  dev.log('runtime=${features.name} simd=${features.supportedFeatures.simd}');
  await OmWasmModule.ensureInitialized();
  final data = OpenMeteoWindData();
  // Argentina-ish tile at zoom 5
  const coords = TileCoordinates(5, 8, 12);
  try {
    final image = await data.tileImage(coords);
    dev.log('tile ${coords.z}/${coords.x}/${coords.y} '
        '${image.width}x${image.height}');
  } on Object catch (e, st) {
    dev.log('FAILED: $e', stackTrace: st);
    rethrow;
  }
}
