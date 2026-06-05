import 'dart:io';
import 'dart:isolate';
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
  WindTileService({
    String? wasmPath,
    Duration readerTtl = const Duration(minutes: 25),
  }) : _wasmPath = wasmPath,
       _readerTtl = readerTtl;

  final String? _wasmPath;
  final Duration _readerTtl;
  final _omBackend = OmHttpBackend();
  final _pngCache = <String, Future<Uint8List>>{};
  Future<OmFileReader>? _gustReaderFuture;
  DateTime? _gustReaderOpenedAt;
  var _tilesRendered = 0;

  /// Renders a 256×256 gust PNG for slippy tile ([z], [x], [y]).
  Future<Uint8List> gustPng({
    required int z,
    required int x,
    required int y,
  }) async {
    await _refreshGustReaderIfExpired();
    final key = '$z/$x/$y';
    final existing = _pngCache[key];
    if (existing != null) return existing;

    final future = _renderGustPng(z: z, x: x, y: y).catchError(
      (Object error, StackTrace stackTrace) {
        _pngCache.remove(key);
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    _pngCache[key] = future;
    return future;
  }

  Future<Uint8List> _renderGustPng({
    required int z,
    required int x,
    required int y,
  }) async {
    final sw = Stopwatch()..start();
    final gustReader = await _openGustReader();
    final tileRead = DwdIconTileRead.forTile(z, x, y);
    final values = await DwdIconTileRead.readValues(
      gustReader.readFloat32,
      tileRead,
    );
    final fetchMs = sw.elapsedMilliseconds;
    sw.reset();
    final png = await Isolate.run(
      () => encodeWindTilePng(values: values, tileRead: tileRead),
    );
    final encodeMs = sw.elapsedMilliseconds;
    _tilesRendered++;
    // ignore: avoid_print
    final gridH = tileRead.yRange.end - tileRead.yRange.start;
    print(
      '[wind] $z/$x/$y  fetch=${fetchMs}ms  encode=${encodeMs}ms'
      '  grid=${tileRead.totalNx}×$gridH',
    );
    if (_tilesRendered % 10 == 0) {
      // ignore: avoid_print
      print(
        '[om-cache] hits=${_LruBlockCacheStats.hits} '
        'misses=${_LruBlockCacheStats.misses} '
        'hit_rate=${(_LruBlockCacheStats.hitRate * 100).toStringAsFixed(1)}%',
      );
    }
    return png;
  }

  Future<void> _refreshGustReaderIfExpired() async {
    final openedAt = _gustReaderOpenedAt;
    if (openedAt == null) return;
    if (DateTime.now().difference(openedAt) < _readerTtl) return;
    // ignore: avoid_print
    print('[wind] gust reader TTL expired; refreshing OM file and PNG cache');
    _gustReaderFuture = null;
    _gustReaderOpenedAt = null;
    _pngCache.clear();
  }

  Future<OmFileReader> _openGustReader() async {
    await _refreshGustReaderIfExpired();
    // `??=` prevents parallel tile requests from each opening the OM file.
    return _gustReaderFuture ??= _initGustReader();
  }

  Future<OmFileReader> _initGustReader() async {
    await ensureWasmRunCliLibrary();
    final wasmPath = _wasmPath ?? _resolveWasmPath();
    await OmWasmModule.ensureInitialized(wasmPath: wasmPath);
    final omUrl = await OmSpatialUrlResolver().resolveOmFileUrl();
    // ignore: avoid_print
    print('[wind] opening OM file: $omUrl');
    final readers = await openWindReaders(Uri.parse(omUrl), _omBackend);
    _gustReaderOpenedAt = DateTime.now();
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

/// Exposes block-cache stats from [OmHttpBackend] for wind tile logging.
abstract final class _LruBlockCacheStats {
  static int get hits => OmHttpBackend.blockCacheHits;
  static int get misses => OmHttpBackend.blockCacheMisses;
  static double get hitRate => OmHttpBackend.blockCacheHitRate;
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
