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
import 'package:where_to_fly/map/wind/open_meteo_wind_tile_provider.dart';
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

  /// When true and [WindMapConfig.nativeLayer], draws gust tiles on the map.
  final bool showWindLayer;

  @override
  State<FlutterMapLayer> createState() => _FlutterMapLayerState();
}

class _FlutterMapLayerState extends State<FlutterMapLayer>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  var _zoom = MapInitializer.initialZoom;
  MapVisibleBounds? _visibleBounds;
  var _tileUrlTemplate = '';
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
  }

  @override
  void didUpdateWidget(FlutterMapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller.setPadding(widget.padding);
    final template = MapConfig.tileUrlTemplateFor(widget.brightness);
    if (template != _tileUrlTemplate) {
      setState(() => _tileUrlTemplate = template);
    }
  }

  @override
  void dispose() {
    widget.controller.disposeNative();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = MapTheme.placeholderFor(widget.brightness);

    return ColoredBox(
      color: placeholder,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: MapInitializer.argentinaCenter,
          initialZoom: MapInitializer.initialZoom,
          onTap: (_, point) => widget.onTap(point),
          onPositionChanged: (camera, hasGesture) {
            setState(() {
              _zoom = camera.zoom;
              final bounds = camera.visibleBounds;
              _visibleBounds = MapVisibleBounds(
                southWest: bounds.southWest,
                northEast: bounds.northEast,
              );
            });
            if (hasGesture) {
              widget.onCameraMove?.call();
            } else {
              widget.onCameraIdle?.call();
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: _tileUrlTemplate,
            subdomains: MapConfig.cartoSubdomains,
            userAgentPackageName: MapConfig.tileUserAgentPackageName,
          ),
          if (widget.showWindLayer && WindMapConfig.nativeLayer)
            TileLayer(
              tileProvider: _windTileProvider,
              maxZoom: 12,
              tileDisplay: const TileDisplay.instantaneous(opacity: 0.85),
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
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'CARTO',
                onTap: () {},
              ),
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
