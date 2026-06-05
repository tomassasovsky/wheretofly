import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// ---------------------------------------------------------------------------
// Native type aliases
// ---------------------------------------------------------------------------

typedef _CreateNative = Pointer<Void> Function(Pointer<Uint8> lut, Int32 n);
typedef _CreateDart = Pointer<Void> Function(Pointer<Uint8> lut, int n);

typedef _DestroyNative = Void Function(Pointer<Void> ctx);
typedef _DestroyDart = void Function(Pointer<Void> ctx);

typedef _RenderNative = Int32 Function(
  Pointer<Void> ctx,
  Pointer<Float> vals,
  Int32 valsLen,
  Int32 gridNx,
  Int32 gridNy,
  Float dx,
  Float dy,
  Float lonMin,
  Float latMin,
  Float lonMax,
  Float latMax,
  Int32 tileX,
  Int32 tileY,
  Int32 tileZ,
  Int32 tileSize,
  Pointer<Uint8> outRgba,
);
typedef _RenderDart = int Function(
  Pointer<Void> ctx,
  Pointer<Float> vals,
  int valsLen,
  int gridNx,
  int gridNy,
  double dx,
  double dy,
  double lonMin,
  double latMin,
  double lonMax,
  double latMax,
  int tileX,
  int tileY,
  int tileZ,
  int tileSize,
  Pointer<Uint8> outRgba,
);

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// GPU-accelerated wind-gust tile renderer backed by a CUDA kernel.
///
/// Use [tryCreate] — it returns `null` when [libgust_tile_gpu.so] is absent or
/// CUDA fails to initialise, allowing callers to fall back to CPU rendering.
class GustTileGpu {
  GustTileGpu._({
    required Pointer<Void> ctx,
    required _RenderDart renderFn,
    required _DestroyDart destroyFn,
    required Pointer<Uint8> outBuffer,
    required int tileSize,
  })  : _ctx = ctx,
        _renderFn = renderFn,
        _destroyFn = destroyFn,
        _outBuffer = outBuffer,
        _outSize = tileSize * tileSize * 4,
        _tileSize = tileSize,
        _valsBuffer = nullptr,
        _valsCapacity = 0;

  final Pointer<Void> _ctx;
  final _RenderDart _renderFn;
  final _DestroyDart _destroyFn;

  Pointer<Float> _valsBuffer;
  int _valsCapacity;

  final Pointer<Uint8> _outBuffer;
  final int _outSize;
  final int _tileSize;

  static const _libName = 'libgust_tile_gpu.so';

  /// Tries to open the CUDA library and create a GPU renderer.
  ///
  /// Checks [GUST_TILE_GPU_LIB_PATH] env var first, then searches
  /// [LD_LIBRARY_PATH]. Returns `null` on any failure so the caller can use
  /// the CPU fallback instead.
  static GustTileGpu? tryCreate({
    required Uint8List lutRgba,
    int tileSize = 256,
  }) {
    DynamicLibrary lib;
    try {
      final envPath = Platform.environment['GUST_TILE_GPU_LIB_PATH'];
      lib = (envPath != null && envPath.isNotEmpty)
          ? DynamicLibrary.open(envPath)
          : DynamicLibrary.open(_libName);
    } on ArgumentError {
      return null;
    }

    final createFn =
        lib.lookupFunction<_CreateNative, _CreateDart>('gust_tile_gpu_create');
    final destroyFn = lib
        .lookupFunction<_DestroyNative, _DestroyDart>('gust_tile_gpu_destroy');
    final renderFn =
        lib.lookupFunction<_RenderNative, _RenderDart>('gust_tile_gpu_render');

    // Copy LUT into native memory, hand it to the CUDA context.
    final lutPtr = malloc<Uint8>(lutRgba.length);
    lutPtr.asTypedList(lutRgba.length).setRange(0, lutRgba.length, lutRgba);
    final ctx = createFn(lutPtr, lutRgba.length ~/ 4);
    malloc.free(lutPtr);

    if (ctx == nullptr) return null;

    final outBuffer = malloc<Uint8>(tileSize * tileSize * 4);
    return GustTileGpu._(
      ctx: ctx,
      renderFn: renderFn,
      destroyFn: destroyFn,
      outBuffer: outBuffer,
      tileSize: tileSize,
    );
  }

  /// Renders one tile as raw RGBA bytes via the CUDA kernel.
  ///
  /// Returns `null` if the kernel fails — caller should fall back to CPU.
  Uint8List? renderRgba({
    required Float32List values,
    required int gridNx,
    required int gridNy,
    required double dx,
    required double dy,
    required double lonMin,
    required double latMin,
    required double lonMax,
    required double latMax,
    required int tileX,
    required int tileY,
    required int tileZ,
  }) {
    if (values.length > _valsCapacity) {
      if (_valsCapacity > 0) malloc.free(_valsBuffer);
      _valsBuffer = malloc<Float>(values.length);
      _valsCapacity = values.length;
    }
    _valsBuffer.asTypedList(_valsCapacity).setRange(0, values.length, values);

    final rc = _renderFn(
      _ctx,
      _valsBuffer,
      values.length,
      gridNx,
      gridNy,
      dx,
      dy,
      lonMin,
      latMin,
      lonMax,
      latMax,
      tileX,
      tileY,
      tileZ,
      _tileSize,
      _outBuffer,
    );

    if (rc != 0) return null;
    return Uint8List.fromList(_outBuffer.asTypedList(_outSize));
  }

  /// Releases all GPU and native resources.
  void dispose() {
    _destroyFn(_ctx);
    if (_valsCapacity > 0) malloc.free(_valsBuffer);
    malloc.free(_outBuffer);
  }
}
