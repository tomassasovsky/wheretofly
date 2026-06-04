import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:wasm_run/wasm_run.dart';

/// Open-Meteo file-format WASM (GPL-2.0-only).
abstract final class OmWasmModule {
  static const errorOk = 0;
  static const headerLegacy = 1;
  static const sizeofDecoder = 104;

  /// `OmDecoder_indexRead_t` / `OmDecoder_dataRead_t` (see om_decoder.h).
  static const sizeofIndexRead = 64;
  static const sizeofDataRead = 64;

  static WasmInstance? _instance;
  static late Uint8List _heap;

  static Future<void> ensureInitialized() async {
    if (_instance != null) return;
    final features = await wasmRuntimeFeatures();
    final asset = features.supportedFeatures.simd
        ? 'assets/om/om_reader_wasm.wasm'
        : 'assets/om/om_reader_wasm_wasmi.wasm';
    final data = await rootBundle.load(asset);
    final module = await compileWasmModule(
      data.buffer.asUint8List(),
      config: features.supportedFeatures.simd
          ? const ModuleConfig(
              wasmtime: ModuleConfigWasmtime(wasmSimd: true),
            )
          : const ModuleConfig(),
    );
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
    instance.getFunction('h')?.call([]);
    _instance = instance;
    _refreshHeap();
  }

  static WasmInstance get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('OmWasmModule.ensureInitialized() was not called');
    }
    return i;
  }

  static Uint8List get heap {
    _refreshHeap();
    return _heap;
  }

  static void _refreshHeap() {
    final memory = instance.getMemory('g');
    if (memory == null) {
      throw StateError('om wasm memory export missing');
    }
    _heap = memory.view;
  }

  static WasmFunction _fn(String export) {
    final f = instance.getFunction(export);
    if (f == null) throw StateError('Missing wasm export $export');
    return f;
  }

  static int malloc(int size) => _fn('G').call([size]).first! as int;

  static void free(int ptr) => _fn('H').call([ptr]);

  static void setI32(int ptr, int value) {
    heap[ptr] = value & 0xff;
    heap[ptr + 1] = (value >> 8) & 0xff;
    heap[ptr + 2] = (value >> 16) & 0xff;
    heap[ptr + 3] = (value >> 24) & 0xff;
  }

  static void setI64(int ptr, int value) {
    ByteData.sublistView(heap, ptr, ptr + 8).setInt64(0, value, Endian.little);
  }

  static int getI32(int ptr) {
    return heap[ptr] |
        (heap[ptr + 1] << 8) |
        (heap[ptr + 2] << 16) |
        (heap[ptr + 3] << 24);
  }

  static int getI64(int ptr) {
    return ByteData.sublistView(heap, ptr, ptr + 8).getInt64(0, Endian.little);
  }

  static void copyToHeap(int ptr, Uint8List bytes) {
    heap.setRange(ptr, ptr + bytes.length, bytes);
  }

  static int callI32(String export, List<Object?> args) =>
      _fn(export).call(args).first! as int;

  static int callI32Void(String export, List<Object?> args) {
    _fn(export).call(args);
    return 0;
  }

  static bool callBool(String export, List<Object?> args) =>
      (_fn(export).call(args).first! as int) != 0;
}

/// Letter export map for om_reader WASM (Open-Meteo file-format-wasm).
abstract final class OmWasmExports {
  static const omDecoderInitDataRead = 'i';
  static const omDecoderInit = 'j';
  static const omVariableGetDimensions = 'k';
  static const omVariableGetChunks = 'l';
  static const omDecoderInitIndexRead = 'm';
  static const omDecoderReadBufferSize = 'n';
  static const omDecoderNextIndexRead = 'o';
  static const omDecoderNextDataRead = 'p';
  static const omDecoderDecodeChunks = 'q';
  static const omHeaderSize = 'r';
  static const omTrailerSize = 's';
  static const omHeaderType = 't';
  static const omTrailerRead = 'u';
  static const omVariableInit = 'v';
  static const omVariableGetName = 'w';
  static const omVariableGetType = 'x';
  static const omVariableGetCompression = 'y';
  static const omVariableGetScaleFactor = 'z';
  static const omVariableGetAddOffset = 'A';
  static const omVariableGetDimensionsCount = 'B';
  static const omVariableGetChildrenCount = 'C';
  static const omVariableGetChildren = 'D';
  static const omVariableGetScalar = 'E';
}
