import 'dart:io';
import 'dart:typed_data';

import 'package:om_smoke/om/dwd_icon_grid.dart';
import 'package:om_smoke/om/om_file_reader.dart';
import 'package:om_smoke/om/om_http_backend.dart';
import 'package:om_smoke/om/om_spatial_url.dart';
import 'package:om_smoke/om/om_wasm_module.dart';
import 'package:om_smoke/om/wasm_run_cli.dart';
import 'package:om_tile_server/wind_arrow_json.dart';
import 'package:om_tile_server/wind_tile_png.dart';

/// Serves Open-Meteo gust raster tiles as PNG (OM decode via WASM).
class WindTileService {
  /// Creates a service; [wasmPath] overrides auto-discovery of the WASM asset.
  WindTileService({String? wasmPath}) : _wasmPath = wasmPath;

  final String? _wasmPath;
  final _pngCache = <String, Future<Uint8List>>{};
  Future<OmFileReader>? _gustReader;

  /// Renders a 256×256 gust PNG for slippy tile ([z], [x], [y]).
  Future<Uint8List> gustPng({
    required int z,
    required int x,
    required int y,
  }) async {
    final key = '$z/$x/$y';
    return _pngCache.putIfAbsent(key, () => _renderGustPng(z: z, x: x, y: y));
  }

  Future<Uint8List> _renderGustPng({
    required int z,
    required int x,
    required int y,
  }) async {
    final gustReader = await _openGustReader();
    final tileRead = DwdIconTileRead.forTile(z, x, y);
    final values = await DwdIconTileRead.readValues(
      gustReader.readFloat32,
      tileRead,
    );
    return encodeWindTilePng(values: values, tileRead: tileRead);
  }

  Future<OmFileReader> _openGustReader() async {
    final existing = _gustReader;
    if (existing != null) return existing;

    final future = _initGustReader();
    _gustReader = future;
    return future;
  }

  Future<OmFileReader> _initGustReader() async {
    await ensureWasmRunCliLibrary();
    final wasmPath = _wasmPath ?? _resolveWasmPath();
    await OmWasmModule.ensureInitialized(wasmPath: wasmPath);
    final omUrl = await OmSpatialUrlResolver().resolveOmFileUrl();
    final backend = OmHttpBackend();
    final readers = await openWindReaders(Uri.parse(omUrl), backend);
    return readers.gust;
  }

  static String _resolveWasmPath() {
    final env = Platform.environment['WIND_OM_WASM_PATH']?.trim();
    if (env != null && env.isNotEmpty) {
      return File(env).absolute.path;
    }

    final cwd = Directory.current.absolute.path;
    final candidates = <String>[
      '$cwd/assets/om/om_reader_wasm.wasm',
      '$cwd/../assets/om/om_reader_wasm.wasm',
      '$cwd/../../assets/om/om_reader_wasm.wasm',
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    throw WindTileServiceException(
      'Open-Meteo OM WASM not found. Set WIND_OM_WASM_PATH or '
      'run from repo root.',
    );
  }
}

/// Thrown when gust tile rendering fails.
class WindTileServiceException implements Exception {
  /// Creates an exception with a diagnostic [message].
  WindTileServiceException(this.message);

  /// Human-readable failure description.
  final String message;

  @override
  String toString() => message;
}
