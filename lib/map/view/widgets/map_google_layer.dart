import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/map_initializer.dart';
import 'package:where_to_fly/map/map_zone_overlay_builder.dart';

/// Imperative handle for [MapGoogleLayer] camera control.
class MapGoogleLayerController {
  gmaps.GoogleMapController? _native;

  // ignore: use_setters_to_change_properties
  void registerNativeController(gmaps.GoogleMapController native) {
    _native = native;
  }

  void clearNativeController() => _native = null;

  void disposeNative() {
    final native = _native;
    clearNativeController();
    if (native != null) {
      try {
        native.dispose();
      } on Object {
        // Platform view may already be gone.
      }
    }
  }

  Future<void> moveTo(LatLng target, {required double zoom}) async {
    final native = _native;
    if (native == null) return;
    try {
      await native.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(target.latitude, target.longitude),
          zoom,
        ),
      );
    } on PlatformException {
      // Map platform view was disposed during navigation.
    }
  }

  Future<void> zoomBy(double delta) async {
    final native = _native;
    if (native == null) return;
    try {
      await native.animateCamera(gmaps.CameraUpdate.zoomBy(delta));
    } on PlatformException {
      // Map platform view was disposed during navigation.
    }
  }

  Future<gmaps.LatLngBounds?> visibleBounds() async {
    final native = _native;
    if (native == null) return null;
    try {
      return native.getVisibleRegion();
    } on PlatformException {
      return null;
    }
  }
}

/// Full-screen Google Map with zone overlays and camera tracking.
class MapGoogleLayer extends StatefulWidget {
  const MapGoogleLayer({
    required this.controller,
    required this.brightness,
    required this.state,
    required this.onTap,
    required this.padding,
    super.key,
  });

  final MapGoogleLayerController controller;
  final Brightness brightness;
  final MapState state;
  final ValueChanged<LatLng> onTap;
  final EdgeInsets padding;

  @override
  State<MapGoogleLayer> createState() => _MapGoogleLayerState();
}

class _MapGoogleLayerState extends State<MapGoogleLayer> {
  var _zoom = MapInitializer.initialZoom;
  gmaps.LatLngBounds? _visibleBounds;

  @override
  void dispose() {
    widget.controller.disposeNative();
    super.dispose();
  }

  Future<void> _updateVisibleRegion() async {
    if (!mounted) return;
    final bounds = await widget.controller.visibleBounds();
    if (!mounted || bounds == null) return;
    setState(() => _visibleBounds = bounds);
  }

  void _onCameraMove(gmaps.CameraPosition position) {
    _zoom = position.zoom;
  }

  Future<void> _onCameraIdle() async {
    await _updateVisibleRegion();
  }

  void _onMapCreated(gmaps.GoogleMapController native) {
    widget.controller.registerNativeController(native);
    unawaited(_updateVisibleRegion());
  }

  LatLng _fromGoogle(gmaps.LatLng point) =>
      LatLng(point.latitude, point.longitude);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.brightness == Brightness.dark;

    return gmaps.GoogleMap(
      style: MapInitializer.mapStyleFor(widget.brightness),
      colorScheme: MapInitializer.mapColorSchemeFor(widget.brightness),
      initialCameraPosition: MapInitializer.initialCamera,
      onMapCreated: _onMapCreated,
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
      onTap: (pos) => widget.onTap(_fromGoogle(pos)),
      circles: MapZoneOverlayBuilder.circles(
        widget.state,
        visibleBounds: _visibleBounds,
        zoom: _zoom,
        isDark: isDark,
      ),
      markers: MapZoneOverlayBuilder.markers(widget.state),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      padding: widget.padding,
    );
  }
}
