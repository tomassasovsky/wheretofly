import 'dart:async' show unawaited;
import 'dart:convert';
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
import 'package:where_to_fly/map/wind/om/wind_arrow_math.dart';
import 'package:where_to_fly/map/wind/om/wind_decode_support.dart';
import 'package:where_to_fly/map/wind/om/wind_tile_math.dart';
import 'package:where_to_fly/map/wind/om/wind_vector_tile.dart';
import 'package:where_to_fly/map/wind_map_config.dart';

/// Loads gust raster tiles and u/v vector data for wind direction arrows.
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
  final _tileCache = <String, Future<ui.Image>>{};
  final _remotePngCache = <String, Future<Uint8List>>{};
  final _vectorCache = <String, Future<WindVectorTile>>{};
  final _remoteArrowCache = <String, Future<List<WindArrowSample>>>{};

  Future<ui.Image> tileImage(TileCoordinates coordinates) async {
    final key = '${coordinates.z}/${coordinates.x}/${coordinates.y}';
    return _tileCache.putIfAbsent(
      key,
      () => _loadTile(coordinates),
    );
  }

  /// u/v grid for direction arrows (local OM decode only).
  Future<WindVectorTile> tileVectors(TileCoordinates coordinates) async {
    if (WindDecodeSupport.hasRemoteTileServer) {
      throw OmFileReaderException(
        'tileVectors is not used with WIND_TILE_BASE_URL; use tileArrowSamples',
      );
    }
    final key = '${coordinates.z}/${coordinates.x}/${coordinates.y}';
    return _cached(
      _vectorCache,
      key,
      () => _loadVectorsFromOmDecode(coordinates),
    );
  }

  /// Arrow samples for one tile.
  ///
  /// JSON on dev server; local subsample otherwise.
  Future<List<WindArrowSample>> tileArrowSamples(
    TileCoordinates coordinates,
  ) async {
    if (WindDecodeSupport.hasRemoteTileServer) {
      return _cached(
        _remoteArrowCache,
        '${coordinates.z}/${coordinates.x}/${coordinates.y}',
        () => _fetchRemoteArrowSamples(coordinates),
      );
    }
    final tile = await tileVectors(coordinates);
    return samplesForTile(tile);
  }

  /// Caches async work; drops the entry on failure so retries work.
  Future<T> _cached<T>(
    Map<String, Future<T>> cache,
    String key,
    Future<T> Function() loader,
  ) async {
    final pending = cache[key];
    if (pending != null) return pending;
    final future = loader();
    cache[key] = future;
    try {
      return await future;
    } on Object {
      final removed = cache.remove(key);
      if (removed != null) unawaited(removed);
      rethrow;
    }
  }

  Future<WindVectorTile> _loadVectorsFromOmDecode(
    TileCoordinates coordinates,
  ) async {
    final localOk = await _ensureLocalDecodeWorks();
    if (!localOk) {
      throw OmFileReaderException(
        'Wind vector decode is not available. Start the tile server '
        '(dart run tooling/om_tile_server/bin/server.dart) and set '
        'WIND_TILE_BASE_URL for iOS.',
      );
    }
    await OmWasmModule.ensureInitialized();
    final session = await _openSession();
    final tileRead = DwdIconTileRead.forTile(
      coordinates.z,
      coordinates.x,
      coordinates.y,
    );
    final u = await DwdIconTileRead.readValues(
      session.uReader.readFloat32,
      tileRead,
    );
    final v = await DwdIconTileRead.readValues(
      session.vReader.readFloat32,
      tileRead,
    );
    _validateVectorValues(u, v);
    return WindVectorTile(tileRead: tileRead, u: u, v: v);
  }

  Future<List<WindArrowSample>> _fetchRemoteArrowSamples(
    TileCoordinates coordinates,
  ) async {
    final base = WindMapConfig.windTileBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse(
      '$base/${coordinates.z}/${coordinates.x}/${coordinates.y}.json',
    );
    final response = await _http.get(uri);
    if (response.statusCode != 200) {
      throw OmFileReaderException(
        'Wind vector HTTP ${response.statusCode} for $uri',
      );
    }
    final json = jsonDecode(response.body);
    if (json is! List) {
      throw OmFileReaderException('Wind vector JSON must be a list');
    }
    return samplesFromRemoteJson(json);
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
    return _remotePngCache.putIfAbsent(key, () => _fetchRemotePng(coordinates));
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

  Future<OpenMeteoWindSession> _openSession() async {
    final existing = _sessionFuture;
    if (existing != null) return existing;
    final future = _createSession();
    _sessionFuture = future;
    return future;
  }

  Future<OpenMeteoWindSession> _createSession() async {
    final omUrl = await _urlResolver.resolveOmFileUrl();
    final root = await OmFileReader.open(Uri.parse(omUrl), backend: _backend);
    final uReader = await root.childByName(WindMapConfig.windUVariable);
    final vReader = await root.childByName(WindMapConfig.windVVariable);
    final gustReader = await root.childByName(WindMapConfig.variable);
    root.dispose();
    return OpenMeteoWindSession(
      uReader: uReader,
      vReader: vReader,
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

  static void _validateVectorValues(Float32List u, Float32List v) {
    var finite = 0;
    for (var i = 0; i < u.length; i++) {
      if (u[i].isFinite &&
          v[i].isFinite &&
          u[i].abs() < 120 &&
          v[i].abs() < 120) {
        finite++;
      }
    }
    if (finite < u.length ~/ 4) {
      throw OmFileReaderException(
        'Wind u/v decode produced invalid samples ($finite finite of '
        '${u.length})',
      );
    }
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
    required this.uReader,
    required this.vReader,
    required this.gustReader,
    required this.backend,
  });

  final OmFileReader uReader;
  final OmFileReader vReader;
  final OmFileReader gustReader;
  final OmHttpBackend backend;

  void dispose() {
    uReader.dispose();
    vReader.dispose();
    gustReader.dispose();
  }
}
