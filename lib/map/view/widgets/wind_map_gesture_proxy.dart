import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:where_to_fly/map/map_camera_controller.dart';

/// Forwards pan and tap to the native map above a wind WebView overlay.
///
/// iOS platform views ignore [IgnorePointer]; [PointerInterceptor] blocks the
/// WebView from receiving touches so the map can be panned from Dart.
class WindMapGestureProxy extends StatefulWidget {
  const WindMapGestureProxy({
    required this.mapController,
    required this.onCheckPoint,
    this.onCameraMove,
    super.key,
  });

  final MapCameraController mapController;
  final ValueChanged<LatLng> onCheckPoint;
  final VoidCallback? onCameraMove;

  @override
  State<WindMapGestureProxy> createState() => _WindMapGestureProxyState();
}

class _WindMapGestureProxyState extends State<WindMapGestureProxy> {
  Offset _pendingDelta = Offset.zero;
  var _panScheduled = false;

  void _onPanUpdate(DragUpdateDetails details) {
    if (details.delta == Offset.zero) return;
    _pendingDelta += details.delta;
    if (_panScheduled) return;
    _panScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _panScheduled = false;
      final delta = _pendingDelta;
      _pendingDelta = Offset.zero;
      if (delta == Offset.zero) return;
      unawaited(
        widget.mapController.panByPixels(delta.dx, delta.dy),
      );
      widget.onCameraMove?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: _onPanUpdate,
        onTapUp: (details) {
          final point = widget.mapController.latLngForScreenOffset(
            details.localPosition,
          );
          if (point != null) widget.onCheckPoint(point);
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}
