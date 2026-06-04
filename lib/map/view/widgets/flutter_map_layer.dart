import 'dart:async';
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/map_camera_controller.dart';
import 'package:where_to_fly/map/map_config.dart';
import 'package:where_to_fly/map/map_initializer.dart';
import 'package:where_to_fly/map/map_theme.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/map_zone_flutter_map_markers.dart';
import 'package:where_to_fly/map/map_zoom_limits.dart';
import 'package:where_to_fly/map/wind/open_meteo_wind_tile_provider.dart';
import 'package:where_to_fly/map/wind/wind_direction_overlay.dart';
import 'package:where_to_fly/map/wind_map_config.dart';

/// Full-screen [FlutterMap] with zone overlays and camera tracking.
class FlutterMapLayer extends StatefulWidget {
  const FlutterMapLayer({
    required this.controller,
    required this.brightness,
    required this.state,
    required this.onTap,
    required this.padding,
    this.onCameraIdle,
    this.onCameraMove,
    this.showWindLayer = false,
    super.key,
  });

  final MapCameraController controller;
  final Brightness brightness;
  final MapState state;
  final ValueChanged<LatLng> onTap;
  final EdgeInsets padding;
  final VoidCallback? onCameraIdle;
  final VoidCallback? onCameraMove;

  /// When true, draws Open-Meteo gust tiles on the map.
  final bool showWindLayer;

  @override
  State<FlutterMapLayer> createState() => _FlutterMapLayerState();
}

/// Nearest-neighbor scaling keeps gust colors stable when tiles are upscaled.
Widget _windTileBuilder(
  BuildContext context,
  Widget tileWidget,
  TileImage tileImage,
) {
  if (tileImage.loadError && tileImage.errorImage != null) {
    return tileWidget;
  }
  final image = tileImage.imageInfo?.image;
  if (image == null) return tileWidget;

  final layerOpacity = tileImage.opacity;
  return RawImage(
    image: image,
    fit: BoxFit.fill,
    filterQuality: FilterQuality.none,
    opacity: layerOpacity == 1 ? null : AlwaysStoppedAnimation(layerOpacity),
  );
}

class _FlutterMapLayerState extends State<FlutterMapLayer>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  var _zoom = MapZoomLimits.fallbackMinZoom;
  var _minZoom = MapZoomLimits.fallbackMinZoom;
  MapVisibleBounds? _visibleBounds;
  var _tileUrlTemplate = '';
  var _initialTilesPrimed = false;

  /// After the user enables wind once, keep the [TileLayer] mounted and toggle
  /// opacity. Unmounting clears flutter_map tile state and the layer often
  /// stays blank until the camera moves.
  var _windLayerRetained = false;
  StreamSubscription<MapEvent>? _mapEvents;
  final _windLayerReset = StreamController<void>.broadcast();
  late final OpenMeteoWindTileProvider _windTileProvider =
      OpenMeteoWindTileProvider();

  @override
  void initState() {
    super.initState();
    widget.controller.setPadding(widget.padding);
    widget.controller.registerNativeController(
      _mapController,
      vsync: this,
    );
    _tileUrlTemplate = MapConfig.tileUrlTemplateFor(widget.brightness);
    _mapEvents = _mapController.mapEventStream.listen(_onMapEvent);
    _retainWindLayerIfNeeded();
  }

  @override
  void didUpdateWidget(FlutterMapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller.setPadding(widget.padding);
    final template = MapConfig.tileUrlTemplateFor(widget.brightness);
    if (template != _tileUrlTemplate) {
      setState(() => _tileUrlTemplate = template);
    }
    if (widget.showWindLayer && !oldWidget.showWindLayer) {
      _retainWindLayerIfNeeded();
    }
  }

  /// Mounts the gust [TileLayer] on first enable and primes tiles once.
  void _retainWindLayerIfNeeded() {
    if (!widget.showWindLayer || _windLayerRetained) return;
    _windLayerRetained = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncCameraState();
          _primeTileLayers();
        }
      });
    });
  }

  @override
  void dispose() {
    unawaited(_mapEvents?.cancel());
    unawaited(_windLayerReset.close());
    widget.controller.disposeNative();
    _mapController.dispose();
    super.dispose();
  }

  double _minZoomForSize(Point<double> mapSize) {
    if (mapSize.x <= 0 || mapSize.y <= 0) return _minZoom;
    return MapZoomLimits.minZoomFittingBoundsHeight(
      mapSize: mapSize,
      bounds: MapInitializer.argentinaBounds,
      padding: widget.padding,
    );
  }

  CameraFit? _initialCameraFitFor(Point<double> mapSize) {
    if (mapSize.x <= 0 || mapSize.y <= 0) return null;
    return CameraFit.insideBounds(
      bounds: MapInitializer.argentinaBounds,
      padding: widget.padding,
      minZoom: _minZoomForSize(mapSize),
    );
  }

  void _onMapEvent(MapEvent event) {
    if (event is! MapEventWithMove) return;
    final camera = event.camera;
    _syncCameraState();
    if (event is MapEventNonRotatedSizeChange) {
      _refitAfterViewportResize(camera.nonRotatedSize);
    }
    if (!_initialTilesPrimed && camera.nonRotatedSize.x > 0) {
      _initialTilesPrimed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _primeTileLayers();
      });
    }
  }

  /// New or late-mounted [TileLayer]s may load tiles without a [MapEvent], so
  /// nothing repaints until the camera moves. Nudge the camera and pulse reset.
  void _primeTileLayers() {
    final camera = _mapController.camera;
    if (camera.nonRotatedSize.x <= 0) return;

    final center = camera.center;
    final zoom = camera.zoom;
    const epsilon = 1e-7;

    _mapController
      ..move(center, zoom + epsilon, id: 'tile_prime')
      ..move(center, zoom, id: 'tile_prime_restore');

    if (widget.showWindLayer && !_windLayerReset.isClosed) {
      _windLayerReset.add(null);
    }
  }

  void _syncCameraState() {
    final camera = _mapController.camera;
    if (camera.nonRotatedSize.x <= 0) return;
    final bounds = camera.visibleBounds;
    setState(() {
      _zoom = camera.zoom;
      _visibleBounds = MapVisibleBounds(
        southWest: bounds.southWest,
        northEast: bounds.northEast,
      );
    });
  }

  void _refitAfterViewportResize(Point<double> mapSize) {
    if (mapSize.x <= 0 || mapSize.y <= 0) return;

    final computed = _minZoomForSize(mapSize);
    if ((computed - _minZoom).abs() <= 0.001) return;

    setState(() => _minZoom = computed);
    _mapController.fitCamera(
      CameraFit.insideBounds(
        bounds: MapInitializer.argentinaBounds,
        padding: widget.padding,
        minZoom: computed,
      ),
    );
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _syncCameraState();
    if (hasGesture) {
      widget.onCameraMove?.call();
    } else {
      widget.onCameraIdle?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = MapTheme.placeholderFor(widget.brightness);

    return ColoredBox(
      color: placeholder,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mapSize = Point(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final effectiveMinZoom = _minZoomForSize(mapSize);

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              minZoom: effectiveMinZoom,
              maxZoom: 18,
              initialCenter: MapInitializer.argentinaCenter,
              initialZoom: effectiveMinZoom,
              initialCameraFit: _initialCameraFitFor(mapSize),
              cameraConstraint: CameraConstraint.containCenter(
                bounds: MapInitializer.argentinaBounds,
              ),
              onTap: (_, point) => widget.onTap(point),
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrlTemplate,
                subdomains: MapConfig.cartoSubdomains,
                userAgentPackageName: MapConfig.tileUserAgentPackageName,
              ),
              if (WindMapConfig.enabled && _windLayerRetained)
                _WindGustTileLayer(
                  visible: widget.showWindLayer,
                  tileProvider: _windTileProvider,
                  reset: _windLayerReset.stream,
                ),
              CircleLayer(
                circles: MapZoneFlutterMapMarkers.build(
                  state: widget.state,
                  visibleBounds: _visibleBounds,
                  zoom: _zoom,
                  isDark: widget.brightness == Brightness.dark,
                  brightness: widget.brightness,
                ),
              ),
              if (widget.showWindLayer &&
                  _windLayerRetained &&
                  WindMapConfig.arrowsEnabled)
                WindDirectionOverlay(
                  mapController: _mapController,
                  data: _windTileProvider.data,
                  brightness: widget.brightness,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Gust raster overlay; stays in the tree once enabled (opacity toggle only).
class _WindGustTileLayer extends StatelessWidget {
  const _WindGustTileLayer({
    required this.visible,
    required this.tileProvider,
    required this.reset,
  });

  final bool visible;
  final OpenMeteoWindTileProvider tileProvider;
  final Stream<void> reset;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: Opacity(
        opacity: visible ? WindMapConfig.windLayerOpacity : 0,
        child: TileLayer(
          tileProvider: tileProvider,
          reset: reset,
          // Gust data is rasterized only through z12; above that, z12 tiles are
          // scaled up. Do not cap [maxZoom] to 12 or the layer disappears when
          // the map zooms in further.
          maxNativeZoom: WindMapConfig.windMaxZoom,
          tileDisplay: const TileDisplay.fadeIn(
            duration: Duration(milliseconds: 120),
          ),
          tileBuilder: _windTileBuilder,
          errorTileCallback: (tile, error, stackTrace) {
            assert(
              () {
                debugPrint(
                  'Wind tile error z=${tile.coordinates.z} '
                  'x=${tile.coordinates.x} y=${tile.coordinates.y}: '
                  '$error',
                );
                return true;
              }(),
              'Wind tile error',
            );
          },
        ),
      ),
    );
  }
}
