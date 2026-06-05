// ignore_for_file: avoid_print

import 'dart:async';

import 'package:backend/services/wind_tile_service.dart';

/// Simulates flutter_map firing many tile requests at once (cold cache).
///
/// `dart run tool/smoke_wind_tiles_parallel.dart` from backend/
Future<void> main() async {
  final service = WindTileService(
    wasmPath: '../assets/om/om_reader_wasm.wasm',
  );

  const tiles = <(int z, int x, int y)>[
    (5, 9, 18),
    (5, 9, 19),
    (5, 9, 20),
    (5, 9, 21),
    (5, 10, 18),
    (5, 10, 19),
    (5, 10, 20),
    (5, 10, 21),
    (5, 11, 18),
    (5, 11, 19),
    (5, 11, 20),
    (5, 11, 21),
  ];

  final sw = Stopwatch()..start();
  final results = await Future.wait(
    tiles.map((t) => service.gustPng(z: t.$1, x: t.$2, y: t.$3)),
  );
  sw.stop();
  print('parallel ${tiles.length} tiles in ${sw.elapsedMilliseconds}ms');
  print('png bytes: ${results.map((b) => b.length).join(', ')}');
}
