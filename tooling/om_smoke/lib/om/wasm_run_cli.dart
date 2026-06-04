import 'package:wasm_run/wasm_run.dart';

/// Ensures the native `wasm_run` dylib is available for CLI / shelf tools.
///
/// Flutter apps register via `WasmRunFlutterNative.registerWith()` in bootstrap.
/// For pure Dart, this downloads or locates `libwasm_run_dart.dylib` (see also
/// `dart run wasm_run:setup`).
Future<void> ensureWasmRunCliLibrary() async {
  if (WasmRunLibrary.isReachable()) return;
  await WasmRunLibrary.setUp(override: false);
}
