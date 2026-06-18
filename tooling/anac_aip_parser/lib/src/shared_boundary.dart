import 'dart:math' as math;

import 'aip_coord.dart';

/// Canonical shared boundary polylines, so that zones whose edges trace the
/// same physical limit line up exactly instead of drawing independently-rounded
/// chords from different AIP sections.
///
/// Two cases this solves:
///  * FIR EZEIZA/MONTEVIDEO limit — shared by TMA BAIRES (ENR 2.1) and the
///    CTRs that say "siguiendo el límite común FIR EZEIZA/MONTEVIDEO".
///  * CTR EZEIZA perimeter — the boundary CTR AEROPARQUE shares with it
///    (AD 2.17 lists the join vertices verbatim, but the approach vertex is
///    rounded ~0.4 NM off, so the shared edge doesn't line up).
abstract final class SharedBoundary {
  /// FIR EZEIZA / MONTEVIDEO common limit (Río de la Plata stretch), ordered
  /// N→S. Vertices are the FIR EZEIZA boundary points from AIP ENR 2.1.
  static const ezeMvd = <AipCoord>[
    AipCoord(-33.833333, -58.516667), // 3350S-05831W
    AipCoord(-34.000000, -58.400000), // 3400S-05824W
    AipCoord(-34.583333, -57.833333), // 3435S-05750W
    AipCoord(-34.883333, -57.100000), // 3453S-05706W
    AipCoord(-36.000000, -54.833333), // 3600S-05450W
  ];

  /// CTR EZEIZA northern/approach edge that CTR AEROPARQUE shares, ordered from
  /// the SE corner toward the W. Vertices verbatim from SAEZ AD 2.17.
  static const ctrEzeNorth = <AipCoord>[
    AipCoord(-34.882778, -58.133889), // 345258S-0580802W
    AipCoord(-34.616111, -58.467222), // 343658S-0582802W
    AipCoord(-34.636111, -58.587222), // 343810S-0583514W
    AipCoord(-34.626111, -58.718889), // 343734S-0584308W
  ];

  /// Resolves a boundary id to its polyline, or null if unknown.
  static List<AipCoord>? byId(String id) {
    switch (id) {
      case 'fir_eze_mvd':
        return ezeMvd;
      case 'ctr_eze_north':
        return ctrEzeNorth;
    }
    return null;
  }

  /// Traces [poly] from the point nearest [from] to the point nearest [to],
  /// returning the snapped entry, any intermediate polyline vertices, and the
  /// snapped exit — all lying exactly on [poly].
  ///
  /// Both endpoints are projected onto the polyline so the result is collinear
  /// with every other zone that follows the same boundary.
  static List<AipCoord> follow(
    AipCoord from,
    AipCoord to,
    List<AipCoord> poly,
  ) {
    final a = _project(from, poly);
    final b = _project(to, poly);
    final out = <AipCoord>[a.point];
    if (a.index <= b.index) {
      for (var i = a.index + 1; i <= b.index; i++) {
        out.add(poly[i]);
      }
    } else {
      for (var i = a.index; i > b.index; i--) {
        out.add(poly[i]);
      }
    }
    out.add(b.point);
    // Drop a duplicate tail when the exit projects exactly onto a vertex.
    if (out.length >= 2 && _near(out[out.length - 1], out[out.length - 2])) {
      out.removeLast();
    }
    return out;
  }

  static bool _near(AipCoord a, AipCoord b) =>
      (a.lat - b.lat).abs() < 1e-6 && (a.lon - b.lon).abs() < 1e-6;

  /// Projects [p] onto [poly], returning the closest point and the index of the
  /// polyline segment's *start* vertex (or the end vertex if it lands on it).
  static _Projection _project(AipCoord p, List<AipCoord> poly) {
    final cosLat = math.cos(p.lat * math.pi / 180);
    double sx(double lon) => lon * cosLat;
    var best = double.infinity;
    var bestIdx = 0;
    var bestPt = poly.first;
    var bestT = 0.0;
    for (var i = 0; i < poly.length - 1; i++) {
      final s = poly[i], e = poly[i + 1];
      final ax = sx(s.lon), ay = s.lat;
      final bx = sx(e.lon), by = e.lat;
      final px = sx(p.lon), py = p.lat;
      final dx = bx - ax, dy = by - ay;
      final len2 = dx * dx + dy * dy;
      var t = len2 == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / len2;
      t = t.clamp(0.0, 1.0);
      final cx = ax + t * dx, cy = ay + t * dy;
      final d = (px - cx) * (px - cx) + (py - cy) * (py - cy);
      if (d < best) {
        best = d;
        bestIdx = i;
        bestT = t;
        bestPt = AipCoord(
          s.lat + t * (e.lat - s.lat),
          s.lon + t * (e.lon - s.lon),
        );
      }
    }
    final idx = bestT >= 1.0 ? bestIdx + 1 : bestIdx;
    return _Projection(bestPt, idx);
  }
}

class _Projection {
  const _Projection(this.point, this.index);
  final AipCoord point;
  final int index;
}
