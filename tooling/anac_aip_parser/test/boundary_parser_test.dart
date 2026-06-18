import 'dart:math' as math;

import 'package:anac_aip_parser/anac_aip_parser.dart';
import 'package:test/test.dart';

void main() {
  final parser = BoundaryParser();
  const densifier = ArcDensifier(arcStepDeg: 1.0);

  group('AipCoord.parse', () {
    test('parses southern western coord', () {
      final c = AipCoord.parse('344927S-0583207W');
      expect(c.lat, closeTo(-34.8242, 0.001));
      expect(c.lon, closeTo(-58.5353, 0.001));
    });

    test('parses northern eastern coord', () {
      final c = AipCoord.parse('010000N-0010000E');
      expect(c.lat, closeTo(1.0, 1e-6));
      expect(c.lon, closeTo(1.0, 1e-6));
    });
  });

  group('BoundaryParser — straight segments', () {
    test('simple triangle', () {
      const text =
          '300000S-0600000W, 300000S-0590000W, 310000S-0590000W hasta 300000S-0600000W.';
      final result = parser.parse(text);
      expect(result, isNotNull);
      final (start, segs) = result!;
      expect(start.lat, closeTo(-30.0, 1e-4));
      expect(segs, hasLength(3));
      expect(segs.every((s) => s is StraightSegment), isTrue);
    });
  });

  group('BoundaryParser — arc segments', () {
    test('detects arc clause and extracts radius + centre', () {
      const text = '''
        345258S-0580802W,
        siguiendo un arco de 20 NM de radio con centro en VOR/DME EZE (344927S-0583207W)
        hacia el Sur hasta 344158S-0585420W.
      ''';
      final result = parser.parse(text);
      expect(result, isNotNull);
      final (start, segs) = result!;
      expect(start.lat, closeTo(-34.8828, 0.001));
      expect(segs, hasLength(1));
      final arc = segs.first as ArcSegment;
      expect(arc.radiusNm, closeTo(20.0, 0.01));
      expect(arc.center.lat, closeTo(-34.8242, 0.001));
      expect(arc.directionHint?.toLowerCase(), 'sur');
    });

    test('explicit clockwise direction', () {
      const text = '''
        300000S-0600000W,
        siguiendo un arco de 10 NM de radio con centro en (300000S-0601000W)
        en sentido horario hasta 301000S-0601000W.
      ''';
      final result = parser.parse(text);
      final segs = result!.$2;
      final arc = segs.first as ArcSegment;
      expect(arc.clockwise, isTrue);
    });

    test('explicit anti-clockwise direction', () {
      const text = '''
        300000S-0600000W,
        siguiendo un arco de 10 NM de radio con centro en (300000S-0601000W)
        en sentido antihorario hasta 301000S-0601000W.
      ''';
      final segs = parser.parse(text)!.$2;
      final arc = segs.first as ArcSegment;
      expect(arc.clockwise, isFalse);
    });
  });

  group('ArcDensifier', () {
    test('full circle has ~360 vertices plus close', () {
      const circleText = '''
        siguiendo una circunferencia de 5 NM de radio con centro en 300000S-0600000W.
      ''';
      final result = parser.parse(circleText);
      expect(result, isNotNull);
      final (start, segs) = result!;
      final ring = densifier.densify(start, segs);
      // 360 / 1° step + closing vertex ≈ 362
      expect(ring.length, greaterThan(350));
      expect(ring.length, lessThan(375));
      // Ring is closed.
      expect(ring.first[0], closeTo(ring.last[0], 1e-6));
      expect(ring.first[1], closeTo(ring.last[1], 1e-6));
    });

    test('arc radius is approximately correct', () {
      // Centre at EZE, 20 NM radius, arc from 72° to 311° CW (south-going).
      // Start bearing from EZE to 345258S-0580802W is ~72°.
      const text = '''
        345258S-0580802W,
        siguiendo un arco de 20 NM de radio con centro en VOR/DME EZE (344927S-0583207W)
        hacia el Sur hasta 344158S-0585420W.
      ''';
      final result = parser.parse(text);
      final (start, segs) = result!;
      final ring = densifier.densify(start, segs);

      // Every arc point should be ≈ 20 NM from EZE.
      const ezeL = -34.8242;
      const ezeN = -58.5353;
      const expectedM = 20 * 1852.0;
      for (final pt in ring) {
        final dist = _haversine(ezeL, ezeN, pt[1], pt[0]);
        expect(dist, closeTo(expectedM, 200)); // within 200 m of 37 km
      }
    });

    test('arc goes via south (CW 72°→311°), not north (CCW)', () {
      const text = '''
        345258S-0580802W,
        siguiendo un arco de 20 NM de radio con centro en VOR/DME EZE (344927S-0583207W)
        hacia el Sur hasta 344158S-0585420W.
      ''';
      final (start, segs) = parser.parse(text)!;
      final ring = densifier.densify(start, segs);
      // At least one point should be south of EZE (lat < -34.82).
      final hasSouthPoint = ring.any((p) => p[1] < -34.9);
      expect(hasSouthPoint, isTrue);
      // No point should be north of EZE (the CCW path would go north).
      final hasNorthPoint = ring.any((p) => p[1] > -34.0);
      expect(hasNorthPoint, isFalse);
    });
  });

  group('Zone database smoke', () {
    test('all entries parse to rings with ≥ 4 points', () {
      for (final entry in zoneDatabase) {
        final result = parser.parse(entry.boundaryText);
        if (result == null) {
          fail('${entry.id}: parse returned null');
        }
        final (start, segs) = result;
        final ring = densifier.densify(start, segs);
        expect(
          ring.length,
          greaterThanOrEqualTo(4),
          reason: '${entry.id} ring too short: ${ring.length}',
        );
      }
    });
  });

  group('FIR shared boundary', () {
    test('"siguiendo el límite FIR" traces the canonical polyline', () {
      // Enter near the FIR limit and follow it south to an exit point. Both
      // endpoints are off the line; the result must snap onto it so the edge
      // is collinear with TMA BAIRES (which uses the same FIR vertices).
      const text = '''
        342058S-0580302W,
        siguiendo el límite común FIR EZEIZA/MONTEVIDEO hacia el Sur
        hasta 343058S-0575402W,
        343058S-0580202W, 341846S-0584608W.
      ''';
      final (start, segs) = parser.parse(text)!;
      expect(
        segs.whereType<BoundaryFollowSegment>(),
        isNotEmpty,
        reason: 'FIR clause should yield a BoundaryFollowSegment',
      );
      final ring = densifier.densify(start, segs);

      // Perpendicular distance (NM) of a point to the FIR segment F1–F2.
      const f1 = SharedBoundary.ezeMvd; // ordered N→S
      final a = f1[1], b = f1[2]; // -34.000/-58.400  and  -34.583/-57.833
      double offNm(List<double> p) {
        const cl = 0.824; // cos(34.4°)
        final ax = a.lon * cl, ay = a.lat;
        final bx = b.lon * cl, by = b.lat;
        final px = p[0] * cl, py = p[1];
        final dx = bx - ax, dy = by - ay;
        final len = math.sqrt(dx * dx + dy * dy);
        return ((px - ax) * dy - (py - ay) * dx).abs() / len * 60;
      }

      // The two FIR-follow vertices (entry & exit) must lie on the FIR line.
      final onLine = ring.where((p) => offNm(p) < 0.05).toList();
      expect(
        onLine.length,
        greaterThanOrEqualTo(2),
        reason: 'entry and exit should snap onto the FIR line',
      );
    });
  });
}

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  const toRad = math.pi / 180;
  final dLat = (lat2 - lat1) * toRad;
  final dLon = (lon2 - lon1) * toRad;
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * toRad) *
          math.cos(lat2 * toRad) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.asin(math.sqrt(a > 1 ? 1 : a));
}
