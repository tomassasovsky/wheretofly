import 'dart:typed_data';

import 'package:om_smoke/om/om_dimension_range.dart';
import 'package:om_smoke/om/om_http_backend.dart';
import 'package:om_smoke/om/om_wasm_module.dart';

/// Reads a variable slice from an Open-Meteo `.om` spatial file over HTTP.
class OmFileReader {
  OmFileReader._({
    required this.backend,
    required this.url,
    required int variablePtr,
    required int variableDataPtr,
  })  : _variablePtr = variablePtr,
        _variableDataPtr = variableDataPtr;

  final OmHttpBackend backend;
  final Uri url;
  final int _variablePtr;
  final int _variableDataPtr;

  final _childMetaCache = <String, ({int offset, int size})?>{};

  static Future<OmFileReader> open(
    Uri omFileUrl, {
    OmHttpBackend? backend,
  }) async {
    final http = backend ?? OmHttpBackend();
    final (variable, dataPtr) = await _loadRootVariable(http, omFileUrl);
    return OmFileReader._(
      backend: http,
      url: omFileUrl,
      variablePtr: variable,
      variableDataPtr: dataPtr,
    );
  }

  static Future<(int variable, int dataPtr)> _loadRootVariable(
    OmHttpBackend backend,
    Uri url,
  ) async {
    final trailerSize =
        OmWasmModule.callI32(OmWasmExports.omTrailerSize, const []);
    final fileSize = await backend.fileSize(url);
    Uint8List? variableData;

    if (fileSize >= trailerSize) {
      final trailerOffset = fileSize - trailerSize;
      final trailerBytes =
          await backend.getBytes(url, trailerOffset, trailerSize);
      final trailerPtr = OmWasmModule.malloc(trailerBytes.length);
      final offsetPtr = OmWasmModule.malloc(8);
      final sizePtr = OmWasmModule.malloc(8);
      try {
        OmWasmModule.copyToHeap(trailerPtr, trailerBytes);
        final ok = OmWasmModule.callBool(
          OmWasmExports.omTrailerRead,
          [trailerPtr, offsetPtr, sizePtr],
        );
        if (ok) {
          final offset = OmWasmModule.getI64(offsetPtr);
          final size = OmWasmModule.getI64(sizePtr);
          variableData = await backend.getBytes(url, offset, size);
        }
      } finally {
        OmWasmModule.free(trailerPtr);
        OmWasmModule.free(offsetPtr);
        OmWasmModule.free(sizePtr);
      }
    }

    variableData ??= await _loadLegacyHeader(backend, url);
    if (variableData == null) {
      throw OmFileReaderException('Not a valid OM file');
    }

    final dataPtr = OmWasmModule.malloc(variableData.length);
    OmWasmModule.copyToHeap(dataPtr, variableData);
    final variable =
        OmWasmModule.callI32(OmWasmExports.omVariableInit, [dataPtr]);
    if (variable == 0) {
      OmWasmModule.free(dataPtr);
      throw OmFileReaderException('om_variable_init failed');
    }
    return (variable, dataPtr);
  }

  static Future<Uint8List?> _loadLegacyHeader(
    OmHttpBackend backend,
    Uri url,
  ) async {
    final headerSize =
        OmWasmModule.callI32(OmWasmExports.omHeaderSize, const []);
    final headerBytes = await backend.getBytes(url, 0, headerSize);
    final headerPtr = OmWasmModule.malloc(headerBytes.length);
    try {
      OmWasmModule.copyToHeap(headerPtr, headerBytes);
      final headerType =
          OmWasmModule.callI32(OmWasmExports.omHeaderType, [headerPtr]);
      if (headerType == OmWasmModule.headerLegacy) {
        return headerBytes;
      }
    } finally {
      OmWasmModule.free(headerPtr);
    }
    return null;
  }

  List<int> getDimensions() {
    final count = OmWasmModule.callI32(
      OmWasmExports.omVariableGetDimensionsCount,
      [_variablePtr],
    );
    final ptr = OmWasmModule.callI32(
      OmWasmExports.omVariableGetDimensions,
      [_variablePtr],
    );
    return List.generate(count, (i) => OmWasmModule.getI64(ptr + i * 8));
  }

  Future<OmFileReader> childByName(String name) async {
    final cached = _childMetaCache[name];
    if (cached != null) {
      if (cached.offset == 0 && cached.size == 0) {
        throw OmFileReaderException('Variable $name not found');
      }
      return _openChild(cached.offset, cached.size);
    }
    final n = OmWasmModule.callI32(
      OmWasmExports.omVariableGetChildrenCount,
      [_variablePtr],
    );
    for (var i = 0; i < n; i++) {
      final meta = _childMetaAt(i);
      if (meta == null) continue;
      final child = await _openChild(meta.offset, meta.size);
      final childName = child.getName();
      if (childName != null) {
        _childMetaCache[childName] = meta;
        if (childName == name) return child;
      }
      child.dispose();
    }
    _childMetaCache[name] = (offset: 0, size: 0);
    throw OmFileReaderException('Variable $name not found');
  }

  ({int offset, int size})? _childMetaAt(int index) {
    final offsetPtr = OmWasmModule.malloc(8);
    final sizePtr = OmWasmModule.malloc(8);
    try {
      final ok = OmWasmModule.callBool(
        OmWasmExports.omVariableGetChildren,
        [_variablePtr, index, 1, offsetPtr, sizePtr],
      );
      if (!ok) return null;
      return (
        offset: OmWasmModule.getI64(offsetPtr),
        size: OmWasmModule.getI64(sizePtr),
      );
    } finally {
      OmWasmModule.free(offsetPtr);
      OmWasmModule.free(sizePtr);
    }
  }

  Future<OmFileReader> _openChild(int offset, int size) async {
    final bytes = await backend.getBytes(url, offset, size);
    final dataPtr = OmWasmModule.malloc(bytes.length);
    OmWasmModule.copyToHeap(dataPtr, bytes);
    final variable =
        OmWasmModule.callI32(OmWasmExports.omVariableInit, [dataPtr]);
    if (variable == 0) {
      OmWasmModule.free(dataPtr);
      throw OmFileReaderException('child om_variable_init failed');
    }
    return OmFileReader._(
      backend: backend,
      url: url,
      variablePtr: variable,
      variableDataPtr: dataPtr,
    );
  }

  String? getName() {
    final lenPtr = OmWasmModule.malloc(2);
    try {
      final valuePtr = OmWasmModule.callI32(
        OmWasmExports.omVariableGetName,
        [_variablePtr, lenPtr],
      );
      final size = OmWasmModule.getI32(lenPtr) & 0xffff;
      if (size == 0 || valuePtr == 0) return null;
      return String.fromCharCodes(
        OmWasmModule.heap.sublist(valuePtr, valuePtr + size),
      );
    } finally {
      OmWasmModule.free(lenPtr);
    }
  }

  Future<Float32List> readFloat32(List<OmDimensionRange> ranges) async {
    var httpCalls = 0;
    final fileDims = getDimensions();
    if (fileDims.length != ranges.length) {
      throw OmFileReaderException('Dimension mismatch');
    }
    final outDims = ranges.map((r) => r.end - r.start).toList();
    final total = outDims.fold<int>(1, (a, b) => a * b);
    final outputPtr = OmWasmModule.malloc(total * 4);
    final decoderPtr = OmWasmModule.malloc(OmWasmModule.sizeofDecoder);
    final readOffsetPtr = OmWasmModule.malloc(ranges.length * 8);
    final readCountPtr = OmWasmModule.malloc(ranges.length * 8);
    final intoOffsetPtr = OmWasmModule.malloc(ranges.length * 8);
    final intoDimPtr = OmWasmModule.malloc(ranges.length * 8);
    try {
      for (var i = 0; i < ranges.length; i++) {
        OmWasmModule.setI64(readOffsetPtr + i * 8, ranges[i].start);
        OmWasmModule.setI64(readCountPtr + i * 8, outDims[i]);
        OmWasmModule.setI64(intoOffsetPtr + i * 8, 0);
        OmWasmModule.setI64(intoDimPtr + i * 8, outDims[i]);
      }
      final err = OmWasmModule.callI32(OmWasmExports.omDecoderInit, [
        decoderPtr,
        _variablePtr,
        ranges.length,
        readOffsetPtr,
        readCountPtr,
        intoOffsetPtr,
        intoDimPtr,
        0,
        1 << 20,
      ]);
      if (err != OmWasmModule.errorOk) {
        throw OmFileReaderException('decoder init error $err');
      }
      final bufferSize = OmWasmModule.callI32(
        OmWasmExports.omDecoderReadBufferSize,
        [decoderPtr],
      );
      final chunkBufferPtr = OmWasmModule.malloc(bufferSize);
      final errorPtr = OmWasmModule.malloc(4);
      try {
        OmWasmModule.setI32(errorPtr, OmWasmModule.errorOk);
        final indexReadPtr = OmWasmModule.malloc(OmWasmModule.sizeofIndexRead);
        try {
          OmWasmModule.callI32Void(
            OmWasmExports.omDecoderInitIndexRead,
            [decoderPtr, indexReadPtr],
          );
          while (OmWasmModule.callBool(
            OmWasmExports.omDecoderNextIndexRead,
            [decoderPtr, indexReadPtr],
          )) {
            final indexOffset = OmWasmModule.getI64(indexReadPtr);
            final indexCount = OmWasmModule.getI64(indexReadPtr + 8);
            httpCalls++;
            final indexBytes = await backend.getBytes(
              url,
              indexOffset,
              indexCount,
            );
            final indexDataPtr = OmWasmModule.malloc(indexBytes.length);
            OmWasmModule.copyToHeap(indexDataPtr, indexBytes);
            final dataReadPtr =
                OmWasmModule.malloc(OmWasmModule.sizeofDataRead);
            try {
              OmWasmModule.callI32Void(
                OmWasmExports.omDecoderInitDataRead,
                [dataReadPtr, indexReadPtr],
              );
              while (OmWasmModule.callBool(
                OmWasmExports.omDecoderNextDataRead,
                [
                  decoderPtr,
                  dataReadPtr,
                  indexDataPtr,
                  BigInt.from(indexCount),
                  errorPtr,
                ],
              )) {
                final dataOffset = OmWasmModule.getI64(dataReadPtr);
                final dataCount = OmWasmModule.getI64(dataReadPtr + 8);
                final chunkIndexPtr = dataReadPtr + 32;
                httpCalls++;
                final blockBytes = await backend.getBytes(
                  url,
                  dataOffset,
                  dataCount,
                );
                final blockPtr = OmWasmModule.malloc(blockBytes.length);
                OmWasmModule.copyToHeap(blockPtr, blockBytes);
                try {
                  final ok = OmWasmModule.callBool(
                    OmWasmExports.omDecoderDecodeChunks,
                    [
                      decoderPtr,
                      chunkIndexPtr,
                      blockPtr,
                      BigInt.from(dataCount),
                      outputPtr,
                      chunkBufferPtr,
                      errorPtr,
                    ],
                  );
                  if (!ok) {
                    throw OmFileReaderException(
                      'decode failed ${OmWasmModule.getI32(errorPtr)}',
                    );
                  }
                } finally {
                  OmWasmModule.free(blockPtr);
                }
              }
            } finally {
              OmWasmModule.free(dataReadPtr);
              OmWasmModule.free(indexDataPtr);
            }
          }
        } finally {
          OmWasmModule.free(indexReadPtr);
        }
      } finally {
        OmWasmModule.free(chunkBufferPtr);
        OmWasmModule.free(errorPtr);
      }
      // Copy before freeing WASM heap — `finally` runs before the return value
      // is delivered to callers; a sublistView would point at freed memory.
      // ignore: avoid_print
      print('[om] http_calls=$httpCalls  total_values=$total');
      return Float32List.fromList(
        OmWasmModule.heap.buffer.asFloat32List(outputPtr, total),
      );
    } finally {
      OmWasmModule.free(outputPtr);
      OmWasmModule.free(decoderPtr);
      OmWasmModule.free(readOffsetPtr);
      OmWasmModule.free(readCountPtr);
      OmWasmModule.free(intoOffsetPtr);
      OmWasmModule.free(intoDimPtr);
    }
  }

  void dispose() {
    OmWasmModule.free(_variableDataPtr);
  }
}

class OmFileReaderException implements Exception {
  OmFileReaderException(this.message);
  final String message;
  @override
  String toString() => message;
}
