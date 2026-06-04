import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/wind/om/dwd_icon_grid.dart';
import 'package:where_to_fly/map/wind/om/wind_arrow_math.dart';
import 'package:where_to_fly/map/wind/om/wind_vector_tile.dart';

void main() {
  test('windSpeedAndBearing eastward wind', () {
    final r = windSpeedAndBearing(5, 0);
    expect(r.speedMs, closeTo(5, 0.01));
    expect(r.bearingRad, closeTo(0, 0.01));
  });

  test('windSpeedAndBearing northward wind', () {
    final r = windSpeedAndBearing(0, 5);
    expect(r.speedMs, closeTo(5, 0.01));
    expect(r.bearingRad, closeTo(math.pi / 2, 0.01));
  });

  test('samplesForTile skips calm and NaN', () {
    final tileRead = DwdIconTileRead.forTile(5, 8, 12);
    final n = tileRead.totalNx * (tileRead.yRange.end - tileRead.yRange.start);
    final u = Float32List(n);
    final v = Float32List(n);
    for (var i = 0; i < n; i++) {
      u[i] = 4;
      v[i] = 0;
    }
    final samples = samplesForTile(
      WindVectorTile(tileRead: tileRead, u: u, v: v),
      stepPx: 32,
    );
    expect(samples, isNotEmpty);
    expect(samples.every((s) => s.speedMs >= 0.5), isTrue);
  });

  test('samplesFromRemoteJson round-trip fields', () {
    final list = samplesFromRemoteJson([
      {'lat': -34.0, 'lon': -58.0, 'u': 3.0, 'v': 4.0},
    ]);
    expect(list, hasLength(1));
    expect(list.single.lat, -34);
    expect(list.single.u, 3);
    expect(list.single.speedMs, closeTo(5, 0.01));
  });

  test('windArrowTail is upwind of tip for eastward flow', () {
    const s = WindArrowSample(
      lat: -34,
      lon: -58,
      u: 5,
      v: 0,
      speedMs: 5,
      bearingRad: 0,
    );
    const len = 50000.0;
    final tip = windArrowTip(s, lengthMeters: len);
    final tail = windArrowTail(s, lengthMeters: len);
    expect(tip.longitude, greaterThan(s.lon));
    expect(tail.longitude, lessThan(s.lon));
    expect(tip.latitude, closeTo(s.lat, 0.01));
    expect(tail.latitude, closeTo(s.lat, 0.01));
  });

  test('uniformArrowSamplesForViewport fills a regular grid', () {
    const bounds = MapVisibleBounds(
      southWest: LatLng(-36, -62),
      northEast: LatLng(-34, -60),
    );
    final candidates = [
      for (var i = 0; i < 20; i++)
        for (var j = 0; j < 20; j++)
          WindArrowSample(
            lat: -35 + i * 0.05,
            lon: -61 + j * 0.05,
            u: 4,
            v: 1,
            speedMs: 4.1,
            bearingRad: 0,
          ),
    ];
    final grid = uniformArrowSamplesForViewport(
      candidates: candidates,
      bounds: bounds,
      viewZoom: 6,
    );
    expect(grid.length, greaterThan(4));
    final lats = grid.map((s) => s.lat).toList()..sort();
    final spacing = lats[1] - lats[0];
    for (var i = 2; i < lats.length; i++) {
      expect(lats[i] - lats[i - 1], closeTo(spacing, spacing * 0.15));
    }
  });

  test('thinArrowSamples caps count', () {
    final many = [
      for (var i = 0; i < 500; i++)
        WindArrowSample(
          lat: i.toDouble(),
          lon: 0,
          u: 1,
          v: 0,
          speedMs: 1,
          bearingRad: 0,
        ),
    ];
    expect(
        thinArrowSamples(many, maxCount: 100).length, lessThanOrEqualTo(100),);
  });

  test('windArrowTip extends downwind from base', () {
    const s = WindArrowSample(
      lat: -34,
      lon: -58,
      u: 5,
      v: 0,
      speedMs: 5,
      bearingRad: 0,
    );
    final tip = windArrowTip(s, lengthMeters: 111320);
    expect(tip.longitude, greaterThan(s.lon));
    expect(tip.latitude, closeTo(s.lat, 0.01));
  });
}
