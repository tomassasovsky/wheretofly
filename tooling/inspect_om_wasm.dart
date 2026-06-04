import 'dart:io';

import 'package:wasm_run/wasm_run.dart';

Future<void> main() async {
  final bytes = await File('assets/om/om_reader_wasm.wasm').readAsBytes();
  final module = await compileWasmModule(bytes);
  for (final i in module.getImports()) {
    i.type?.mapOrNull(
      func: (f) {
        print(
          '${i.module}.${i.name} in=${f.field0.parameters} out=${f.field0.results}',
        );
      },
    );
  }
  for (final e in module.getExports()) {
    print(e);
  }
}
