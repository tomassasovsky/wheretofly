import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasm_run/wasm_run.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await WasmRunLibrary.setUp(
      override: false,
      isFlutter: true,
      loadAsset: rootBundle.load,
    );
  });

  test('compiles Open-Meteo om reader wasm (simd)', () async {
    final data = await rootBundle.load('assets/om/om_reader_wasm.wasm');
    final module = await compileWasmModule(
      data.buffer.asUint8List(),
      config: const ModuleConfig(
        wasmtime: ModuleConfigWasmtime(wasmSimd: true),
      ),
    );
    expect(module.getExports(), isNotEmpty);
  });

  test('compiles Open-Meteo om reader wasm (wasmi)', () async {
    final data = await rootBundle.load('assets/om/om_reader_wasm_wasmi.wasm');
    final module = await compileWasmModule(
      data.buffer.asUint8List(),
      config: const ModuleConfig(wasmi: ModuleConfigWasmi()),
    );
    expect(module.getExports(), isNotEmpty);
  });
}
