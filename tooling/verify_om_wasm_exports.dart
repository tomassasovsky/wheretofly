import 'dart:io';

import 'package:wasm_run/wasm_run.dart';

Future<void> main() async {
  for (final path in [
    'assets/om/om_reader_wasm.wasm',
    'assets/om/om_reader_wasm_wasmi.wasm',
  ]) {
    stdout.writeln('--- $path');
    final module = await compileWasmModule(await File(path).readAsBytes());
    final builder = module.builder()
      ..addImport(
        'a',
        'a',
        WasmFunction.voidReturn(
          (int a, int b, int c, int d) {},
          params: const [
            ValueTy.i32,
            ValueTy.i32,
            ValueTy.i32,
            ValueTy.i32,
          ],
        ),
      )
      ..addImport(
        'a',
        'b',
        WasmFunction.voidReturn((int code) {}, params: const [ValueTy.i32]),
      )
      ..addImport('a', 'c', WasmFunction.voidReturn(() {}, params: const []))
      ..addImport('a', 'd', WasmFunction.voidReturn(() {}, params: const []))
      ..addImport(
        'a',
        'e',
        WasmFunction(
          (int which, double ms) => 0,
          params: const [ValueTy.i32, ValueTy.f64],
          results: const [ValueTy.i32],
        ),
      )
      ..addImport(
        'a',
        'f',
        WasmFunction(
          (int size) => 0,
          params: const [ValueTy.i32],
          results: const [ValueTy.i32],
        ),
      );
    final instance = await builder.build();
    for (final name in ['h', 'g', 'r', 's', 'G', 'H', 'i', 'q']) {
      final fn = instance.getFunction(name);
      final mem = instance.getMemory(name);
      if (fn != null || mem != null) {
        stdout.writeln('  $name fn=${fn != null} mem=${mem != null}');
      }
    }
    instance.dispose();
  }
}
