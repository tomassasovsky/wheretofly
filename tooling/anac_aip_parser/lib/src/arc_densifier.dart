import 'dart:math' as math;

import 'aip_coord.dart';
import 'aip_segment.dart';
import 'shared_boundary.dart';

/// Converts a parsed boundary (start coord + segment list) into a dense
/// `[longitude, latitude]` polygon ring suitable for GeoJSON.
///
/// Arc segments are densified into polylines using the spherical forward
/// geodesic formula at [arcStepDeg]-degree bearing steps (default 1°).
/// The error vs WGS-84 ellipsoid is < 15 m across Argentina — well below
/// the AIP text coordinate resolution (1 arcsecond ≈ 30 m).
class ArcDensifier {
  const ArcDensifier({this.arcStepDeg = 1.0});

  final double arcStepDeg;

  static const double _nmToM = 1852.0;
  static const double _earthR = 6371000.0;
  static const double _deg2rad = math.pi / 180.0;
  static const double _rad2deg = 180.0 / math.pi;

  /// Returns a closed ring of `[lon, lat]` pairs for GeoJSON.
  List<List<double>> densify(AipCoord start, List<AipSegment> segments) {
    final ring = <List<double>>[];
    ring.add([start.lon, start.lat]);

    AipCoord current = start;

    for (final seg in segments) {
      switch (seg) {
        case StraightSegment():
          ring.add([seg.to.lon, seg.to.lat]);
          current = seg.to;

        case ArcSegment():
          final pts = _densifyArc(current, seg);
          ring.addAll(pts);
          current = seg.to;

        case CircleSegment():
          final pts = _densifyCircle(seg);
          // Replace what we have — a full circle IS the boundary.
          ring.clear();
          ring.addAll(pts);
          current = seg.center;

        case BoundaryFollowSegment():
          final poly = SharedBoundary.byId(seg.boundaryId);
          if (poly == null) {
            // Unknown boundary — fall back to a straight chord.
            ring.add([seg.to.lon, seg.to.lat]);
            current = seg.to;
            break;
          }
          final path = SharedBoundary.follow(current, seg.to, poly);
          // Snap the entry vertex onto the boundary (removes the chord kink),
          // then trace the polyline to the snapped exit.
          if (path.isNotEmpty && ring.isNotEmpty) {
            ring[ring.length - 1] = [path.first.lon, path.first.lat];
            for (final p in path.skip(1)) {
              ring.add([p.lon, p.lat]);
            }
            current = path.last;
          }
      }
    }

    // Close the ring if needed.
    if (ring.length > 1) {
      final first = ring.first;
      final last = ring.last;
      if (first[0] != last[0] || first[1] != last[1]) {
        ring.add([first[0], first[1]]);
      }
    }

    return ring;
  }

  // ---------------------------------------------------------------------------
  // Arc densification
  // ---------------------------------------------------------------------------

  List<List<double>> _densifyArc(AipCoord from, ArcSegment seg) {
    final c = seg.center;
    final radiusM = seg.radiusNm * _nmToM;

    final startB = _bearing(c.lat, c.lon, from.lat, from.lon);
    final endB = _bearing(c.lat, c.lon, seg.to.lat, seg.to.lon);

    final cw =
        seg.clockwise ?? _inferClockwise(startB, endB, seg.directionHint);

    return _arcPoints(c.lat, c.lon, radiusM, startB, endB, cw);
  }

  List<List<double>> _densifyCircle(CircleSegment seg) {
    final c = seg.center;
    final radiusM = seg.radiusNm * _nmToM;
    return _arcPoints(c.lat, c.lon, radiusM, 0, 360, true);
  }

  List<List<double>> _arcPoints(
    double cLat,
    double cLon,
    double radiusM,
    double startB,
    double endB,
    bool cw,
  ) {
    final points = <List<double>>[];
    var b = startB;

    double target = endB;
    if (cw) {
      if (target <= startB) target += 360;
    } else {
      if (target >= startB) target -= 360;
    }

    // Guard against degenerate full-circle arcs (start ≈ end, large sweep).
    final fullCircle =
        (startB - endB).abs() < 0.01 || (startB - endB).abs() > 359.9;
    if (fullCircle) target = cw ? startB + 360 : startB - 360;

    final step = cw ? arcStepDeg : -arcStepDeg;
    while (cw ? b < target : b > target) {
      final p = _destination(cLat, cLon, b % 360, radiusM);
      points.add([p.$2, p.$1]); // [lon, lat]
      b += step;
    }
    // Add the exact end point.
    final end = _destination(cLat, cLon, endB % 360, radiusM);
    points.add([end.$2, end.$1]);
    return points;
  }

  // ---------------------------------------------------------------------------
  // Arc direction inference from "hacia el DIRECTION"
  // ---------------------------------------------------------------------------

  bool _inferClockwise(double startB, double endB, String? hint) {
    if (hint == null) return _shorterArcIsCw(startB, endB);
    final hintB = _hintBearing(hint);
    if (hintB < 0) return _shorterArcIsCw(startB, endB);
    // "hacia el <dir>" gives the initial direction of *travel* along the arc,
    // not a compass bearing the arc sweeps through. Travelling clockwise
    // (increasing bearing from the centre) the boundary point moves toward
    // startB + 90°; anticlockwise it moves toward startB - 90°. Pick the sense
    // whose travel direction is closest to the hinted compass direction.
    final cwTravel = (startB + 90) % 360;
    final ccwTravel = (startB - 90 + 360) % 360;
    return _angularGap(cwTravel, hintB) <= _angularGap(ccwTravel, hintB);
  }

  static bool _shorterArcIsCw(double startB, double endB) {
    final cw = (endB - startB + 360) % 360;
    return cw <= 180;
  }

  /// Smallest absolute angle (degrees, 0-180) between bearings [a] and [b].
  static double _angularGap(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  static double _hintBearing(String hint) {
    return switch (hint.toLowerCase()) {
      'norte' || 'n' => 0,
      'nne' => 22.5,
      'ne' => 45,
      'ene' => 67.5,
      'este' || 'e' => 90,
      'ese' => 112.5,
      'se' => 135,
      'sse' => 157.5,
      'sur' || 's' => 180,
      'sso' => 202.5,
      'so' => 225,
      'oso' => 247.5,
      'oeste' || 'o' || 'w' => 270,
      'ono' => 292.5,
      'no' => 315,
      'nno' => 337.5,
      _ => -1,
    };
  }

  // ---------------------------------------------------------------------------
  // Spherical geodesic helpers
  // ---------------------------------------------------------------------------

  /// Initial bearing from (lat1, lon1) to (lat2, lon2), in degrees [0, 360).
  static double _bearing(double lat1, double lon1, double lat2, double lon2) {
    final lat1R = lat1 * _deg2rad;
    final lat2R = lat2 * _deg2rad;
    final dLonR = (lon2 - lon1) * _deg2rad;
    final y = math.sin(dLonR) * math.cos(lat2R);
    final x =
        math.cos(lat1R) * math.sin(lat2R) -
        math.sin(lat1R) * math.cos(lat2R) * math.cos(dLonR);
    return (math.atan2(y, x) * _rad2deg + 360) % 360;
  }

  /// Point at [distM] metres from (lat1, lon1) on bearing [bearingDeg].
  /// Returns (lat, lon) in degrees.
  static (double, double) _destination(
    double lat1,
    double lon1,
    double bearingDeg,
    double distM,
  ) {
    final d = distM / _earthR;
    final brng = bearingDeg * _deg2rad;
    final lat1R = lat1 * _deg2rad;
    final lon1R = lon1 * _deg2rad;
    final lat2 = math.asin(
      math.sin(lat1R) * math.cos(d) +
          math.cos(lat1R) * math.sin(d) * math.cos(brng),
    );
    final lon2 =
        lon1R +
        math.atan2(
          math.sin(brng) * math.sin(d) * math.cos(lat1R),
          math.cos(d) - math.sin(lat1R) * math.sin(lat2),
        );
    return (lat2 * _rad2deg, ((lon2 * _rad2deg) + 540) % 360 - 180);
  }
}
