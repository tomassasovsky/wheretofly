import 'dart:math' show Point;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/map_initializer.dart';
import 'package:where_to_fly/map/map_layout.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/map_zoom_limits.dart';
import 'package:where_to_fly/map/wind/om/dwd_icon_grid.dart';
import 'package:where_to_fly/map/wind/om/om_tile_rasterizer.dart';
import 'package:where_to_fly/map/wind/om/wind_visible_tiles.dart';
import 'package:where_to_fly/map/wind_map_config.dart';

/// Phone-sized viewport used in map zoom tests.
const kWindTestMapSize = Size(390, 844);

/// Bottom chrome padding matching [MapPage] layout in widget tests.
const kWindTestMapPadding = EdgeInsets.only(
  top: MapLayout.topOverlayInset,
  bottom: 116,
);

/// Minimum opaque pixels for a tile to count as rendered (not blank/error).
const kMinOpaqueWindPixels = 100;

/// Tracks wind [TileLayer] loads in widget tests.
class WindTileLoadTracker {
  final loaded = <TileCoordinates>{};
  final failed = <TileCoordinates>{};
}

/// Slippy tiles covering the Argentina viewport at phone min zoom.
List<TileCoordinates> argentinaWindTilesAtPhoneMinZoom() {
  final minZoom = MapZoomLimits.minZoomFittingBoundsHeight(
    mapSize: Point(kWindTestMapSize.width, kWindTestMapSize.height),
    bounds: MapInitializer.argentinaBounds,
    padding: kWindTestMapPadding,
  );
  final camera = MapCamera(
    crs: const Epsg3857(),
    center: MapInitializer.argentinaBounds.center,
    zoom: minZoom,
    rotation: 0,
    nonRotatedSize: Point(kWindTestMapSize.width, kWindTestMapSize.height),
  );
  final bounds = camera.visibleBounds;
  return visibleWindTiles(
    bounds: MapVisibleBounds(
      southWest: bounds.southWest,
      northEast: bounds.northEast,
    ),
    zoom: minZoom,
  );
}

/// Constant plausible gust field for a tile read spec.
Float32List syntheticGustValues(DwdIconTileRead tileRead) {
  final ny = tileRead.yRange.end - tileRead.yRange.start;
  final values = Float32List(tileRead.totalNx * ny);
  values.fillRange(0, values.length, 8.0);
  return values;
}

Future<int> countOpaquePixels(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  expect(byteData, isNotNull);
  final bytes = byteData!.buffer.asUint8List();
  var opaque = 0;
  for (var i = 3; i < bytes.length; i += 4) {
    if (bytes[i] > 0) opaque++;
  }
  return opaque;
}

Future<void> expectWindImageRenders(
  ui.Image image, {
  String? label,
}) async {
  addTearDown(image.dispose);
  final opaque = await countOpaquePixels(image);
  expect(
    opaque,
    greaterThan(kMinOpaqueWindPixels),
    reason: label ?? 'wind tile should contain visible gust pixels',
  );
}

/// [TileProvider] that rasterizes synthetic gust tiles (no network / WASM).
class SyntheticWindTileProvider extends TileProvider {
  SyntheticWindTileProvider({required this.tracker});

  final WindTileLoadTracker tracker;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _SyntheticWindTileImage(
      coordinates: coordinates,
      tracker: tracker,
    );
  }
}

@immutable
class _SyntheticWindTileImage extends ImageProvider<_SyntheticWindTileImage> {
  const _SyntheticWindTileImage({
    required this.coordinates,
    required this.tracker,
  });

  final TileCoordinates coordinates;
  final WindTileLoadTracker tracker;

  @override
  Future<_SyntheticWindTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _SyntheticWindTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(key),
      scale: 1,
    );
  }

  Future<ui.Codec> _loadCodec(_SyntheticWindTileImage key) async {
    try {
      final tileRead = DwdIconTileRead.forTile(
        key.coordinates.z,
        key.coordinates.x,
        key.coordinates.y,
      );
      final image = await rasterizeWindTile(
        values: syntheticGustValues(tileRead),
        tileRead: tileRead,
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData!.buffer.asUint8List();
      var opaque = 0;
      for (var i = 3; i < bytes.length; i += 4) {
        if (bytes[i] > 0) opaque++;
      }
      if (opaque <= kMinOpaqueWindPixels) {
        throw StateError(
          'Tile ${key.coordinates.z}/${key.coordinates.x}/'
          '${key.coordinates.y} has only $opaque opaque pixels',
        );
      }
      key.tracker.loaded.add(key.coordinates);
      return ui.instantiateImageCodec(bytes);
    } on Object catch (error, stackTrace) {
      key.tracker.failed.add(key.coordinates);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _SyntheticWindTileImage && coordinates == other.coordinates;

  @override
  int get hashCode => coordinates.hashCode;
}

/// Pumps frames until [condition] is true or [maxSteps] is exceeded.
Future<void> pumpUntil(
  WidgetTester tester, {
  required bool Function() condition,
  Duration step = const Duration(milliseconds: 100),
  int maxSteps = 150,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (condition()) return;
    await tester.pump(step);
  }
  fail('Timed out after ${maxSteps * step.inMilliseconds}ms');
}

/// Builds a [FlutterMap] at Argentina min zoom with a wind [TileLayer].
Widget buildWindMapTestWidget({
  required MapController controller,
  required SyntheticWindTileProvider tileProvider,
}) {
  final minZoom = MapZoomLimits.minZoomFittingBoundsHeight(
    mapSize: Point(kWindTestMapSize.width, kWindTestMapSize.height),
    bounds: MapInitializer.argentinaBounds,
    padding: kWindTestMapPadding,
  );
  return SizedBox(
    width: kWindTestMapSize.width,
    height: kWindTestMapSize.height,
    child: FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: MapInitializer.argentinaCenter,
        initialZoom: minZoom,
        initialCameraFit: CameraFit.insideBounds(
          bounds: MapInitializer.argentinaBounds,
          padding: kWindTestMapPadding,
          minZoom: minZoom,
        ),
        minZoom: minZoom,
        maxZoom: 18,
        cameraConstraint: CameraConstraint.containCenter(
          bounds: MapInitializer.argentinaBounds,
        ),
      ),
      children: [
        TileLayer(
          tileProvider: tileProvider,
          maxNativeZoom: WindMapConfig.windMaxZoom,
          evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
        ),
      ],
    ),
  );
}

/// Expected tiles from the map camera after the first frame.
List<TileCoordinates> visibleTilesForController(MapController controller) {
  final bounds = controller.camera.visibleBounds;
  return visibleWindTiles(
    bounds: MapVisibleBounds(
      southWest: bounds.southWest,
      northEast: bounds.northEast,
    ),
    zoom: controller.camera.zoom,
  );
}
