import 'dart:ui';

import 'package:latlong2/latlong.dart';

/// Platform-neutral circle overlay for a single fly zone.
class MapZoneCircleStyle {
  const MapZoneCircleStyle({
    required this.id,
    required this.center,
    required this.radiusMeters,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  final String id;
  final LatLng center;
  final double radiusMeters;
  final Color fillColor;
  final Color strokeColor;
  final int strokeWidth;
}
