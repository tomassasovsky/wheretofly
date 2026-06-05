import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:where_to_fly/map/wind/om/dwd_icon_grid.dart';
import 'package:where_to_fly/map/wind/om/om_file_reader.dart';
import 'package:where_to_fly/map/wind/om/om_http_backend.dart';
import 'package:where_to_fly/map/wind/om/om_spatial_url.dart';
import 'package:where_to_fly/map/wind/om/om_tile_rasterizer.dart';
import 'package:where_to_fly/map/wind/om/om_wasm_module.dart';
import 'package:where_to_fly/map/wind/om/wind_decode_support.dart';
import 'package:where_to_fly/map/wind/om/wind_tile_math.dart';
import 'package:where_to_fly/map/wind_map_config.dart';

/// Loads gust raster tiles for the wind overlay.
class OpenMeteoWindData {
  OpenMeteoWindData({
    OmSpatialUrlResolver? urlResolver,
    OmHttpBackend? backend,
    http.Client? httpClient,
  })  : _urlResolver = urlResolver ?? OmSpatialUrlResolver(),
        _backend = backend ?? OmHttpBackend(),
        _http = httpClient ?? http.Client();

  final OmSpatialUrlResolver _urlResolver;
  final OmHttpBackend _backend;
  final http.Client _http;
  Future<bool>? _localDecodeWorks;

  Future<OpenMeteoWindSession>? _sessionFuture;
  DateTime? _sessionOpenedAt;
  static const _sessionTtl = Duration(minutes: 25);
  final _tileCache = <String, Future<ui.Image>>{};
  final _remotePngCache = <String, Future<Uint8List>>{};

  Future<ui.Image> tileImage(TileCoordinates coordinates) async {
    final key = '${coordinates.z}/${coordinates.x}/${coordinates.y}';
    final existing = _tileCache[key];
    if (existing != null) return existing;

    final future = _loadTile(coordinates).catchError(
      (Object error, StackTrace stackTrace) {
        _tileCache.remove(key);
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    _tileCache[key] = future;
    return future;
  }

  Future<ui.Image> _loadTile(TileCoordinates coordinates) async {
    if (WindDecodeSupport.hasRemoteTileServer) {
      return _loadRemotePng(coordinates);
    }
    final localOk = await _ensureLocalDecodeWorks();
    if (!localOk) {
      throw OmFileReaderException(
        'Wind OM decode is not available on this device. Start the tile '
        'server (dart run tooling/om_tile_server/bin/server.dart). Debug iOS '
        'simulator uses http://127.0.0.1:8765 by default; on a physical '
        'iPhone use --dart-define=WIND_TILE_BASE_URL=http://<host-ip>:8765',
      );
    }
    await OmWasmModule.ensureInitialized();
    final session = await _openSession();
    return _loadTileFromOm(session, coordinates);
  }

  Future<bool> _ensureLocalDecodeWorks() async {
    final pending = _localDecodeWorks;
    if (pending != null) return pending;
    final future = WindDecodeSupport.localOmWasmWorks();
    _localDecodeWorks = future;
    return future;
  }

  Future<Uint8List> tilePngBytes(TileCoordinates coordinates) async {
    final key = '${coordinates.z}/${coordinates.x}/${coordinates.y}';
    final existing = _remotePngCache[key];
    if (existing != null) return existing;

    final future = _fetchRemotePng(coordinates).catchError(
      (Object error, StackTrace stackTrace) {
        _remotePngCache.remove(key);
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    _remotePngCache[key] = future;
    return future;
  }

  Future<Uint8List> _fetchRemotePng(TileCoordinates coordinates) async {
    final base = WindMapConfig.windTileBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse(
      '$base/${coordinates.z}/${coordinates.x}/${coordinates.y}.png',
    );
    final response = await _http.get(uri);
    if (response.statusCode != 200) {
      throw OmFileReaderException(
        'Wind tile HTTP ${response.statusCode} for $uri',
      );
    }
    return response.bodyBytes;
  }

  Future<ui.Image> _loadRemotePng(TileCoordinates coordinates) async {
    final bytes = await tilePngBytes(coordinates);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  Future<void> _refreshSessionIfExpired() async {
    final openedAt = _sessionOpenedAt;
    if (openedAt == null) return;
    if (DateTime.now().difference(openedAt) < _sessionTtl) return;
    _sessionFuture = null;
    _sessionOpenedAt = null;
    _tileCache.clear();
    _remotePngCache.clear();
  }

  Future<OpenMeteoWindSession> _openSession() async {
    await _refreshSessionIfExpired();
    final existing = _sessionFuture;
    if (existing != null) return existing;
    final future = _createSession();
    _sessionFuture = future;
    return future;
  }

  Future<OpenMeteoWindSession> _createSession() async {
    final omUrl = await _urlResolver.resolveOmFileUrl();
    final root = await OmFileReader.open(Uri.parse(omUrl), backend: _backend);
    final gustReader = await root.childByName(WindMapConfig.variable);
    root.dispose();
    _sessionOpenedAt = DateTime.now();
    return OpenMeteoWindSession(
      gustReader: gustReader,
      backend: _backend,
    );
  }

  Future<ui.Image> _loadTileFromOm(
    OpenMeteoWindSession session,
    TileCoordinates coordinates,
  ) async {
    final tileRead = DwdIconTileRead.forTile(
      coordinates.z,
      coordinates.x,
      coordinates.y,
    );
    final values = await DwdIconTileRead.readValues(
      session.gustReader.readFloat32,
      tileRead,
    );
    _validateGustValues(values, tileRead, coordinates);
    return rasterizeWindTile(values: values, tileRead: tileRead);
  }

  static void _validateGustValues(
    Float32List values,
    DwdIconTileRead tileRead,
    TileCoordinates coordinates,
  ) {
    var plausible = 0;
    for (final v in values) {
      if (v.isFinite && v >= 0 && v < 80) plausible++;
    }
    final grid = tileRead.toGrid();
    final centerLat = tile2lat(coordinates.y + 0.5, coordinates.z);
    final centerLon = tile2lon(coordinates.x + 0.5, coordinates.z);
    final center = grid.valueAt(values, centerLat, centerLon);
    final centerOk = center.isFinite && center >= 0 && center < 80;
    final enoughPlausible = plausible >= values.length ~/ 4;
    if (!centerOk || !enoughPlausible) {
      throw OmFileReaderException(
        'Wind gust decode produced invalid samples ($plausible plausible '
        'of ${values.length}, center=$center)',
      );
    }
  }
}

class OpenMeteoWindSession {
  OpenMeteoWindSession({
    required this.gustReader,
    required this.backend,
  });

  final OmFileReader gustReader;
  final OmHttpBackend backend;

  void dispose() {
    gustReader.dispose();
  }
}
