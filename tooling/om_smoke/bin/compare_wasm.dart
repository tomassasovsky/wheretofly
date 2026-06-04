// ignore_for_file: avoid_print

import 'package:om_smoke/om/om_dimension_range.dart';
import 'package:om_smoke/om/om_file_reader.dart';
import 'package:om_smoke/om/om_http_backend.dart';
import 'package:om_smoke/om/om_spatial_url.dart';
import 'package:om_smoke/om/om_wasm_module.dart';

Future<void> main(List<String> args) async {
  final root = args.isNotEmpty ? args[0] : '../../';
  final omUrl = await OmSpatialUrlResolver().resolveOmFileUrl();
  final ranges = [
    OmDimensionRange(start: 500, end: 520),
    OmDimensionRange(start: 1000, end: 1020),
  ];

  for (final wasm in [
    '$root/assets/om/om_reader_wasm.wasm',
    '$root/assets/om/om_reader_wasm_wasmi.wasm',
  ]) {
    OmWasmModule.ensureInitialized(wasmPath: wasm);
    // ignore: invalid_use_of_visible_for_testing_member
    final _ = OmWasmModule.instance;
    // Force re-init by clearing - hack for compare
    print('\n=== $wasm ===');
    final rootReader = await OmFileReader.open(
      Uri.parse(omUrl),
      backend: OmHttpBackend(),
    );
    final gust = await rootReader.childByName('wind_gusts_10m');
    rootReader.dispose();
    final values = await gust.readFloat32(ranges);
    gust.dispose();
    print('sample: ${values.take(8).toList()}');
    print(
      'min=${values.reduce((a, b) => a < b ? a : b)} max=${values.reduce((a, b) => a > b ? a : b)}',
    );
  }
}
