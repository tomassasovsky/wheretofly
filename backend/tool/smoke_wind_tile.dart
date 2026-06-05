// ignore_for_file: avoid_print

import 'package:backend/services/wind_tile_service.dart';

/// `dart run tool/smoke_wind_tile.dart` from backend/
Future<void> main() async {
  final service = WindTileService(
    wasmPath: '../assets/om/om_reader_wasm.wasm',
  );
  final png = await service.gustPng(z: 5, x: 10, y: 12);
  if (png.length < 1000) {
    throw StateError('PNG too small: ${png.length} bytes');
  }
  print('ok: ${png.length} bytes');
}
