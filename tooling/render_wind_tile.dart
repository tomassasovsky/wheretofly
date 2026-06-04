import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_map/flutter_map.dart';
import 'package:wasm_run/wasm_run.dart';
import 'package:where_to_fly/map/wind/om/om_wasm_module.dart';
import 'package:where_to_fly/map/wind/om/open_meteo_wind_data.dart';

/// Renders one wind tile to /tmp/wind_tile.png (dev smoke test).
Future<void> main() async {
  await WasmRunLibrary.setUp(override: false);
  await OmWasmModule.ensureInitialized();
  final data = OpenMeteoWindData();
  final image = await data.tileImage(const TileCoordinates(5, 8, 4));
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  const path = '/tmp/wind_tile.png';
  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('Wrote $path (${bytes.lengthInBytes} bytes)');
}
