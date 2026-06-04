/// Center and zoom of the map camera.
class MapCameraSnapshot {
  const MapCameraSnapshot({
    required this.lat,
    required this.lon,
    required this.zoom,
  });

  final double lat;
  final double lon;
  final double zoom;
}
