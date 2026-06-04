import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/wind/om/open_meteo_wind_data.dart';
import 'package:where_to_fly/map/wind/om/wind_arrow_math.dart';
import 'package:where_to_fly/map/wind/om/wind_tile_math.dart';
import 'package:where_to_fly/map/wind/om/wind_visible_tiles.dart';
import 'package:where_to_fly/map/wind/wind_arrow_painter.dart';

/// Wind direction arrows drawn in map space (fast canvas, pans with the map).
class WindDirectionOverlay extends StatefulWidget {
  const WindDirectionOverlay({
    required this.mapController,
    required this.data,
    required this.brightness,
    super.key,
  });

  final MapController mapController;
  final OpenMeteoWindData data;
  final Brightness brightness;

  @override
  State<WindDirectionOverlay> createState() => _WindDirectionOverlayState();
}

class _WindDirectionOverlayState extends State<WindDirectionOverlay> {
  List<WindArrowSample> _samples = const [];
  List<WindArrowSample> _rawCandidates = const [];
  int _loadGeneration = 0;
  String? _loadedTileKey;
  StreamSubscription<MapEvent>? _mapEvents;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mapEvents = widget.mapController.mapEventStream.listen(_onMapEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadSamples());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_mapEvents?.cancel());
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventNonRotatedSizeChange) {
      _scheduleLoad();
    }
  }

  MapVisibleBounds? _effectiveBounds() {
    final camera = widget.mapController.camera;
    if (camera.nonRotatedSize.x <= 0) return null;
    final b = camera.visibleBounds;
    return MapVisibleBounds(southWest: b.southWest, northEast: b.northEast);
  }

  static List<TileCoordinates> _tilesNearestCenterFirst(
    List<TileCoordinates> tiles,
    MapVisibleBounds bounds,
  ) {
    final centerLat =
        (bounds.southWest.latitude + bounds.northEast.latitude) / 2;
    final centerLon =
        (bounds.southWest.longitude + bounds.northEast.longitude) / 2;
    final sorted = List<TileCoordinates>.from(tiles)
      ..sort((a, b) {
        final da = _approxTileDist(a, centerLat, centerLon);
        final db = _approxTileDist(b, centerLat, centerLon);
        return da.compareTo(db);
      });
    return sorted;
  }

  static double _approxTileDist(TileCoordinates t, double lat, double lon) {
    final tileLat = tile2lat(t.y + 0.5, t.z);
    final tileLon = tile2lon(t.x + 0.5, t.z);
    final dLon = tileLon - lon;
    final dLat = tileLat - lat;
    return dLon * dLon + dLat * dLat;
  }

  static String _tileKey(List<TileCoordinates> tiles) {
    final parts = tiles.map((t) => '${t.z}/${t.x}/${t.y}').toList()..sort();
    return parts.join('|');
  }

  void _scheduleLoad() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      unawaited(_loadSamples());
    });
  }

  void _publishSamples({
    required List<WindArrowSample> candidates,
    required MapVisibleBounds bounds,
    required double viewZoom,
  }) {
    setState(
      () => _samples = uniformArrowSamplesForViewport(
        candidates: candidates,
        bounds: bounds,
        viewZoom: viewZoom,
      ),
    );
  }

  void _regridFromCache(MapVisibleBounds bounds, double viewZoom) {
    if (_rawCandidates.isEmpty) return;
    _publishSamples(
      candidates: _rawCandidates,
      bounds: bounds,
      viewZoom: viewZoom,
    );
  }

  Future<void> _loadSamples() async {
    final bounds = _effectiveBounds();
    if (bounds == null) return;

    final zoom = widget.mapController.camera.zoom;
    var tiles = visibleWindArrowTiles(bounds: bounds, viewZoom: zoom);
    if (tiles.isEmpty) return;
    tiles = _tilesNearestCenterFirst(tiles, bounds);

    final tileKey = _tileKey(tiles);
    final dataZ = tiles.first.z;

    if (tileKey == _loadedTileKey && _rawCandidates.isNotEmpty) {
      _regridFromCache(bounds, zoom);
      return;
    }

    final gen = ++_loadGeneration;
    final merged = <WindArrowSample>[];
    var failures = 0;

    for (final tile in tiles) {
      if (!mounted || gen != _loadGeneration) return;
      try {
        merged.addAll(await widget.data.tileArrowSamples(tile));
        if (mounted && gen == _loadGeneration) {
          _rawCandidates = List<WindArrowSample>.from(merged);
          _publishSamples(
            candidates: _rawCandidates,
            bounds: bounds,
            viewZoom: zoom,
          );
        }
      } on Object catch (error) {
        failures++;
        if (kDebugMode) {
          debugPrint(
            'Wind arrow tile ${tile.z}/${tile.x}/${tile.y} failed: $error',
          );
        }
      }
    }

    if (!mounted || gen != _loadGeneration) return;

    _loadedTileKey = tileKey;
    _rawCandidates = List<WindArrowSample>.from(merged);
    _publishSamples(
      candidates: _rawCandidates,
      bounds: bounds,
      viewZoom: zoom,
    );

    if (kDebugMode) {
      debugPrint(
        'Wind arrows: ${_samples.length} drawn '
        '(${tiles.length} tiles at z=$dataZ, $failures failed)',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_samples.isEmpty) return const SizedBox.shrink();

    final isDark = widget.brightness == Brightness.dark;
    final color = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final outline = isDark ? Colors.black87 : Colors.white70;
    final map = MapCamera.of(context);

    return MobileLayerTransformer(
      child: CustomPaint(
        size: Size(map.size.x, map.size.y),
        painter: WindArrowPainter(
          samples: _samples,
          map: map,
          color: color,
          outlineColor: outline,
        ),
      ),
    );
  }
}
