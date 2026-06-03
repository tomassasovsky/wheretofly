import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/map_camera_controller.dart';
import 'package:where_to_fly/map/view/widgets/wind_map_web_view.dart';

/// Keeps the main map camera and wind overlay aligned.
///
/// Wind sync uses instant camera jumps (no animation) and at most one JS update
/// per frame so panning stays responsive.
class MapWindCameraCoordinator {
  MapWindCameraCoordinator({
    required MapCameraController map,
    required WindMapController wind,
  })  : _map = map,
        _wind = wind;

  final MapCameraController _map;
  final WindMapController _wind;
  var _windSyncScheduled = false;

  MapCameraController get map => _map;

  WindMapController get wind => _wind;

  /// Copies the native map camera to the wind overlay (coalesced per frame).
  void syncWindToMap() {
    if (_windSyncScheduled) return;
    _windSyncScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _windSyncScheduled = false;
      final camera = _map.readCamera();
      if (camera != null) {
        _wind.syncFrom(camera);
      }
    });
  }

  Future<void> zoomBy(double delta) async {
    await _map.zoomBy(delta);
    syncWindToMap();
  }

  Future<void> moveMapTo(LatLng target, {required double zoom}) =>
      _map.moveTo(target, zoom: zoom);
}
