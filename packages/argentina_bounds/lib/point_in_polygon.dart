/// Ray-casting point-in-polygon for geographic rings (lat/lon tuples).
bool pointInPolygonRing(
  double lat,
  double lon,
  List<(double lat, double lon)> ring,
) {
  var inside = false;
  final n = ring.length;
  if (n < 3) return false;

  for (var i = 0, j = n - 1; i < n; j = i++) {
    final yi = ring[i].$1;
    final xi = ring[i].$2;
    final yj = ring[j].$1;
    final xj = ring[j].$2;
    if (yi == yj) continue;
    if ((yi > lat) != (yj > lat)) {
      final xIntersect = (xj - xi) * (lat - yi) / (yj - yi) + xi;
      if (lon < xIntersect) inside = !inside;
    }
  }
  return inside;
}

bool pointInAnyRing(
  double lat,
  double lon,
  List<List<(double lat, double lon)>> rings,
) {
  for (final ring in rings) {
    if (pointInPolygonRing(lat, lon, ring)) return true;
  }
  return false;
}
