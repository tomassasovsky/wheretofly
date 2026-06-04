import 'dart:io';

import 'package:wasm_run/wasm_run.dart';

Future<void> main() async {
  final bytes = await File('assets/om/om_reader_wasm.wasm').readAsBytes();
  final module = await compileWasmModule(bytes);
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
      WasmFunction((int which, double ms) => 0,
          params: const [ValueTy.i32, ValueTy.f64], results: const [ValueTy.i32],),
    )
    ..addImport(
      'a',
      'f',
      WasmFunction((int size) => 0,
          params: const [ValueTy.i32], results: const [ValueTy.i32],),
    );
  final instance = await builder.build();

  final init = instance.getFunction('h');
  init?.call([]);

  final headerSize = instance.getFunction('r')!.call([]);
  print('header size $headerSize');
  instance.dispose();
}
