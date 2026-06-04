import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/wind/om/wind_tile_math.dart';
import 'package:where_to_fly/map/wind/om/wind_vector_tile.dart';

/// One arrow sample in geographic coordinates.
class WindArrowSample {
  const WindArrowSample({
    required this.lat,
    required this.lon,
    required this.u,
    required this.v,
    required this.speedMs,
    required this.bearingRad,
  });

  final double lat;
  final double lon;

  /// 10 m wind components (east, north) in m/s.
  final double u;
  final double v;

  /// Wind speed √(u² + v²) in m/s.
  final double speedMs;

  /// Radians: direction wind **blows toward** (0 = east, π/2 = north).
  final double bearingRad;
}

/// Parses speed and bearing from 10 m u/v components (east, north) in m/s.
({double speedMs, double bearingRad}) windSpeedAndBearing(double u, double v) {
  final speed = math.sqrt(u * u + v * v);
  if (speed < 1e-6) return (speedMs: 0, bearingRad: 0);
  return (speedMs: speed, bearingRad: math.atan2(v, u));
}

/// Grid subsample step (px) for arrow JSON / local decode by slippy [z].
int arrowStepPxForZoom(int z) {
  if (z <= 4) return 64;
  if (z <= 6) return 48;
  if (z <= 8) return 32;
  return 16;
}

/// Target pixel spacing between arrow centers on screen.
const windArrowScreenSpacingPx = 56.0;

/// Lat/lon cell size for a uniform viewport grid at [viewZoom].
double arrowGridLatSpacingDegrees(double viewZoom, double centerLat) {
  final scale =
      156543.03 * math.cos(centerLat * math.pi / 180) / math.pow(2, viewZoom);
  final meters = windArrowScreenSpacingPx * scale;
  return (meters / 111320.0).clamp(0.06, 2.5);
}

double arrowGridLonSpacingDegrees(double viewZoom, double centerLat) {
  final latSpacing = arrowGridLatSpacingDegrees(viewZoom, centerLat);
  final cosLat = math.cos(centerLat * math.pi / 180).abs().clamp(0.2, 1.0);
  return latSpacing / cosLat;
}

/// One averaged u/v bucket on a fixed world grid (aligned across tiles).
class _WindArrowCell {
  double u = 0;
  double v = 0;
  int count = 0;

  void add(WindArrowSample s) {
    u += s.u;
    v += s.v;
    count++;
  }
}

/// Even arrow density: ~56px apart on screen at the current zoom.
List<WindArrowSample> uniformArrowSamplesForViewport({
  required List<WindArrowSample> candidates,
  required MapVisibleBounds bounds,
  required double viewZoom,
}) {
  if (candidates.isEmpty) return const [];

  final centerLat = (bounds.southWest.latitude + bounds.northEast.latitude) / 2;
  final latSpacing = arrowGridLatSpacingDegrees(viewZoom, centerLat);
  final lonSpacing = arrowGridLonSpacingDegrees(viewZoom, centerLat);

  final buckets = <int, _WindArrowCell>{};
  for (final s in candidates) {
    if (!_inBounds(s, bounds)) continue;
    final bx = (s.lon / lonSpacing).floor();
    final by = (s.lat / latSpacing).floor();
    buckets.putIfAbsent(Object.hash(bx, by), _WindArrowCell.new).add(s);
  }

  final bx0 = (bounds.southWest.longitude / lonSpacing).floor();
  final bx1 = (bounds.northEast.longitude / lonSpacing).floor();
  final by0 = (bounds.southWest.latitude / latSpacing).floor();
  final by1 = (bounds.northEast.latitude / latSpacing).floor();

  final out = <WindArrowSample>[];
  for (var by = by0; by <= by1; by++) {
    for (var bx = bx0; bx <= bx1; bx++) {
      final cell = buckets[Object.hash(bx, by)];
      if (cell == null || cell.count == 0) continue;
      final u = cell.u / cell.count;
      final v = cell.v / cell.count;
      final sv = windSpeedAndBearing(u, v);
      if (sv.speedMs < 0.5) continue;
      out.add(
        WindArrowSample(
          lat: (by + 0.5) * latSpacing,
          lon: (bx + 0.5) * lonSpacing,
          u: u,
          v: v,
          speedMs: sv.speedMs,
          bearingRad: sv.bearingRad,
        ),
      );
    }
  }
  return out;
}

bool _inBounds(WindArrowSample s, MapVisibleBounds bounds) {
  return s.lat >= bounds.southWest.latitude &&
      s.lat <= bounds.northEast.latitude &&
      s.lon >= bounds.southWest.longitude &&
      s.lon <= bounds.northEast.longitude;
}

/// Geographic tip of an arrow polyline (wind blows from tail toward tip).
LatLng windArrowTip(
  WindArrowSample sample, {
  required double lengthMeters,
}) {
  final speed = sample.speedMs;
  if (speed < 0.5) return LatLng(sample.lat, sample.lon);
  final len = lengthMeters * (speed / 8).clamp(0.5, 1.8);
  final latRad = sample.lat * math.pi / 180;
  final cosLat = math.cos(latRad).abs().clamp(0.2, 1.0);
  final dLat = (sample.v / speed) * len / 111320;
  final dLon = (sample.u / speed) * len / (111320 * cosLat);
  return LatLng(sample.lat + dLat, sample.lon + dLon);
}

/// Upwind end of the arrow (opposite motion vector).
LatLng windArrowTail(
  WindArrowSample sample, {
  required double lengthMeters,
}) {
  final speed = sample.speedMs;
  if (speed < 0.5) return LatLng(sample.lat, sample.lon);
  final len = lengthMeters * (speed / 8).clamp(0.5, 1.8);
  final latRad = sample.lat * math.pi / 180;
  final cosLat = math.cos(latRad).abs().clamp(0.2, 1.0);
  final dLat = (-sample.v / speed) * len / 111320;
  final dLon = (-sample.u / speed) * len / (111320 * cosLat);
  return LatLng(sample.lat + dLat, sample.lon + dLon);
}

/// Downsample when tile merge exceeds [maxCount].
List<WindArrowSample> thinArrowSamples(
  List<WindArrowSample> samples, {
  required int maxCount,
}) {
  if (samples.length <= maxCount) return samples;
  final stride = (samples.length / maxCount).ceil();
  return [
    for (var i = 0; i < samples.length; i += stride) samples[i],
  ];
}

/// Subsampled arrow points for one [WindVectorTile].
List<WindArrowSample> samplesForTile(
  WindVectorTile tile, {
  int? stepPx,
  double minSpeedMs = 0.5,
}) {
  final grid = tile.tileRead.toGrid();
  final z = tile.tileRead.z;
  final step = stepPx ?? arrowStepPxForZoom(z);
  final x = tile.tileRead.x;
  final y = tile.tileRead.y;
  final out = <WindArrowSample>[];

  for (var i = 0; i < 256; i += step) {
    final lat = tile2lat(y + (i + 0.5) / 256, z);
    for (var j = 0; j < 256; j += step) {
      final lon = tile2lon(x + (j + 0.5) / 256, z);
      final u = grid.valueAt(tile.u, lat, lon);
      final v = grid.valueAt(tile.v, lat, lon);
      if (!u.isFinite || !v.isFinite) continue;
      final sv = windSpeedAndBearing(u, v);
      if (sv.speedMs < minSpeedMs) continue;
      out.add(
        WindArrowSample(
          lat: lat,
          lon: lon,
          u: u,
          v: v,
          speedMs: sv.speedMs,
          bearingRad: sv.bearingRad,
        ),
      );
    }
  }
  return out;
}

WindArrowSample windArrowSampleFromJson(Map<String, dynamic> json) {
  final u = (json['u'] as num).toDouble();
  final v = (json['v'] as num).toDouble();
  final sv = windSpeedAndBearing(u, v);
  return WindArrowSample(
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    u: u,
    v: v,
    speedMs: sv.speedMs,
    bearingRad: sv.bearingRad,
  );
}

List<WindArrowSample> samplesFromRemoteJson(List<dynamic> jsonList) {
  return [
    for (final row in jsonList)
      if (row is Map<String, dynamic>)
        windArrowSampleFromJson(row)
      else if (row is Map)
        windArrowSampleFromJson(row.cast<String, dynamic>()),
  ];
}
