import 'package:latlong2/latlong.dart';

/// Axis-aligned map viewport bounds in WGS84 coordinates.
class MapVisibleBounds {
  const MapVisibleBounds({
    required this.southWest,
    required this.northEast,
  });

  final LatLng southWest;
  final LatLng northEast;
}
