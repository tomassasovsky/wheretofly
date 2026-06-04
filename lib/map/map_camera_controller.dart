import 'dart:async';
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Imperative handle for the [FlutterMap] layer (camera moves and bounds).
class MapCameraController {
  MapController? _map;
  TickerProvider? _vsync;
  EdgeInsets _padding = EdgeInsets.zero;
  AnimationController? _cameraAnimation;

  static const _moveDuration = Duration(milliseconds: 450);
  static const _zoomDuration = Duration(milliseconds: 200);

  void registerNativeController(
    MapController map, {
    required TickerProvider vsync,
  }) {
    _map = map;
    _vsync = vsync;
  }

  void clearNativeController() {
    _stopCameraAnimation();
    _map = null;
    _vsync = null;
  }

  // ignore: use_setters_to_change_properties — called from map layer lifecycle
  void setPadding(EdgeInsets padding) => _padding = padding;

  void disposeNative() {
    clearNativeController();
  }

  Future<void> moveTo(LatLng target, {required double zoom}) async {
    final map = _map;
    if (map == null) return;
    final endCenter = _mapCenterForVisiblePoint(map.camera, target, zoom);
    await _animateCamera(
      endCenter: endCenter,
      endZoom: zoom,
      duration: _moveDuration,
    );
  }

  Future<void> zoomBy(double delta) async {
    final map = _map;
    if (map == null) return;
    try {
      final camera = map.camera;
      await _animateCamera(
        endCenter: camera.center,
        endZoom: camera.zoom + delta,
        duration: _zoomDuration,
      );
    } on Exception {
      // Map widget was disposed during navigation.
    }
  }

  /// Geographic center so [point] sits in the padded viewport at [zoom].
  ///
  /// Matches [MapControllerImpl.moveRaw] padding math, but applied once at a
  /// fixed zoom so animated zoom does not drift.
  LatLng _mapCenterForVisiblePoint(
    MapCamera camera,
    LatLng point,
    double zoom,
  ) {
    final offset = _paddingOffset();
    if (offset == Offset.zero) return point;

    final projected = camera.project(point, zoom);
    return camera.unproject(
      camera.rotatePoint(
        projected,
        projected - Point(offset.dx, offset.dy),
      ),
      zoom,
    );
  }

  Future<void> _animateCamera({
    required LatLng endCenter,
    required double endZoom,
    required Duration duration,
  }) async {
    final map = _map;
    final vsync = _vsync;
    if (map == null) return;

    final camera = map.camera;
    final beginCenter = camera.center;
    final beginZoom = camera.zoom;

    if (beginCenter == endCenter && beginZoom == endZoom) return;

    if (vsync == null) {
      map.move(endCenter, endZoom);
      return;
    }

    _stopCameraAnimation();

    final controller = AnimationController(duration: duration, vsync: vsync);
    _cameraAnimation = controller;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    final latTween = Tween<double>(
      begin: beginCenter.latitude,
      end: endCenter.latitude,
    );
    final lngTween = Tween<double>(
      begin: beginCenter.longitude,
      end: endCenter.longitude,
    );
    final zoomTween = Tween<double>(begin: beginZoom, end: endZoom);

    final completer = Completer<void>();

    void tick() {
      // Never pass [move] offset while zoom changes — pixel offsets drift.
      map.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    }

    controller
      ..addListener(tick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          controller
            ..removeListener(tick)
            ..dispose();
          if (_cameraAnimation == controller) {
            _cameraAnimation = null;
          }
          if (!completer.isCompleted) completer.complete();
        }
      });

    unawaited(controller.forward());
    return completer.future;
  }

  void _stopCameraAnimation() {
    final controller = _cameraAnimation;
    if (controller == null) return;
    controller
      ..stop()
      ..dispose();
    _cameraAnimation = null;
  }

  Offset _paddingOffset() {
    if (_padding == EdgeInsets.zero) return Offset.zero;
    return Offset(
      (_padding.left - _padding.right) / 2,
      (_padding.top - _padding.bottom) / 2,
    );
  }
}
