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
    this.boundary,
  });

  final String id;
  final LatLng center;
  final double radiusMeters;
  final Color fillColor;
  final Color strokeColor;
  final int strokeWidth;

  /// True boundary ring when the zone has real geometry; rendered as a polygon
  /// instead of a circle. `null` zones fall back to [center]/[radiusMeters].
  final List<LatLng>? boundary;
}
