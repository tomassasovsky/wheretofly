import 'dart:math' as math;
import 'dart:typed_data';

import 'package:om_smoke/om/om_dimension_range.dart';
import 'package:om_smoke/om/wind_tile_math.dart';

/// DWD ICON global regular grid (see Open-Meteo weather-map-layer domains).
class DwdIconGrid {
  DwdIconGrid._({
    required this.nx,
    required this.ny,
    required this.dx,
    required this.dy,
    required this.longitudeWrap,
    required this.bounds,
  });

  factory DwdIconGrid.forRanges(List<OmDimensionRange> ranges) {
    final yRange = ranges[0];
    final xRange = ranges[1];
    final nx = xRange.end - xRange.start;
    final ny = yRange.end - yRange.start;
    final lonMin = DwdIconGridData.lonMin + DwdIconGridData.dx * xRange.start;
    final latMin = DwdIconGridData.latMin + DwdIconGridData.dy * yRange.start;
    final lonMax = DwdIconGridData.lonMin + DwdIconGridData.dx * xRange.end;
    final latMax = DwdIconGridData.latMin + DwdIconGridData.dy * yRange.end;
    return DwdIconGrid._(
      nx: nx,
      ny: ny,
      dx: DwdIconGridData.dx,
      dy: DwdIconGridData.dy,
      longitudeWrap: lonMax - lonMin >= 359.875,
      bounds: [lonMin, latMin, lonMax, latMax],
    );
  }

  final int nx;
  final int ny;
  final double dx;
  final double dy;
  final bool longitudeWrap;
  final List<double> bounds;

  double valueAt(Float32List values, double lat, double lon) {
    if (!longitudeWrap && (lon < bounds[0] || lon > bounds[2])) {
      return double.nan;
    }
    if (lat < bounds[1] || lat >= bounds[3]) {
      return double.nan;
    }
    final y = ((lat - bounds[1]) / dy).floor();
    final yFraction = ((lat - bounds[1]) % dy) / dy;
    final x = math.min(((lon - bounds[0]) / dx).floor(), nx - 1);
    final tileDx = longitudeWrap && lon >= bounds[2] - dx ? dx * 2 : dx;
    final xFraction = ((lon - bounds[0]) % tileDx) / tileDx;
    return _interpolateLinear(
      values: values,
      x: x,
      y: y,
      xFraction: xFraction,
      yFraction: yFraction,
      nx: nx,
      longitudeWrap: longitudeWrap,
    );
  }

  List<OmDimensionRange> coveringRanges({
    required double south,
    required double west,
    required double north,
    required double east,
  }) {
    final xSegments =
        DwdIconTileRead._xSegmentsForBounds(west: west, east: east);
    if (xSegments.length != 1) {
      throw StateError(
        'Bounds cross the antimeridian with multiple x segments; '
        'use DwdIconTileRead.forTile',
      );
    }
    return [
      DwdIconTileRead._yRangeForBounds(south: south, north: north),
      xSegments.single,
    ];
  }

  static List<OmDimensionRange> rangesForTile(int z, int x, int y) {
    final read = DwdIconTileRead.forTile(z, x, y);
    return [read.yRange, read.xSegments.first];
  }
}

/// OM read specification for one map tile (may use multiple x slices).
class DwdIconTileRead {
  const DwdIconTileRead({
    required this.z,
    required this.x,
    required this.y,
    required this.yRange,
    required this.xSegments,
  });

  final int z;
  final int x;
  final int y;
  final OmDimensionRange yRange;
  final List<OmDimensionRange> xSegments;

  int get totalNx => xSegments.fold(0, (sum, r) => sum + r.end - r.start);

  static DwdIconTileRead forTile(int z, int x, int y) {
    final south = tile2lat(y + 1, z);
    final north = tile2lat(y.toDouble(), z);
    final west = tile2lon(x.toDouble(), z);
    final east = tile2lon(x + 1.0, z);
    final yRange = _yRangeForBounds(south: south, north: north);
    final xSegments = _xSegmentsForBounds(west: west, east: east);
    return DwdIconTileRead(
      z: z,
      x: x,
      y: y,
      yRange: yRange,
      xSegments: xSegments,
    );
  }

  static OmDimensionRange _yRangeForBounds({
    required double south,
    required double north,
  }) {
    final yStart =
        ((south - DwdIconGridData.latMin) / DwdIconGridData.dy).floor();
    final yEnd = ((north - DwdIconGridData.latMin) / DwdIconGridData.dy).ceil();
    return OmDimensionRange(
      start: yStart.clamp(0, DwdIconGridData.ny),
      end: yEnd.clamp(0, DwdIconGridData.ny),
    );
  }

  static List<OmDimensionRange> _xSegmentsForBounds({
    required double west,
    required double east,
  }) {
    final xStart =
        ((west - DwdIconGridData.lonMin) / DwdIconGridData.dx).floor();
    final xEnd = ((east - DwdIconGridData.lonMin) / DwdIconGridData.dx).ceil();
    OmDimensionRange clampX(int start, int end) => OmDimensionRange(
          start: start.clamp(0, DwdIconGridData.nx),
          end: end.clamp(0, DwdIconGridData.nx),
        );

    if (west <= east) {
      return [clampX(xStart, xEnd)];
    }
    final segments = <OmDimensionRange>[clampX(xStart, DwdIconGridData.nx)];
    if (xEnd > 0) {
      segments.add(clampX(0, xEnd));
    }
    return segments;
  }

  DwdIconGrid toGrid() {
    final south = tile2lat(y + 1, z);
    final north = tile2lat(y.toDouble(), z);
    final west = tile2lon(x.toDouble(), z);
    final east = tile2lon(x + 1.0, z);
    final eastBound = west > east ? 180.0 : east;
    return DwdIconGrid._(
      nx: totalNx,
      ny: yRange.end - yRange.start,
      dx: DwdIconGridData.dx,
      dy: DwdIconGridData.dy,
      longitudeWrap: false,
      bounds: [west, south, eastBound, north],
    );
  }

  static Future<Float32List> readValues(
    Future<Float32List> Function(List<OmDimensionRange> ranges) read,
    DwdIconTileRead spec,
  ) async {
    if (spec.xSegments.length == 1) {
      return read([spec.yRange, spec.xSegments.single]);
    }
    final ny = spec.yRange.end - spec.yRange.start;
    final parts = <Float32List>[];
    for (final xRange in spec.xSegments) {
      parts.add(await read([spec.yRange, xRange]));
    }
    final nx = spec.totalNx;
    final out = Float32List(ny * nx);
    for (var row = 0; row < ny; row++) {
      var col = 0;
      for (final part in parts) {
        final segNx = part.length ~/ ny;
        final rowStart = row * segNx;
        out.setRange(row * nx + col, row * nx + col + segNx, part, rowStart);
        col += segNx;
      }
    }
    return out;
  }
}

class DwdIconGridData {
  const DwdIconGridData();

  static const nx = 2879;
  static const ny = 1441;
  static const latMin = -90.0;
  static const lonMin = -180.0;
  static const dx = 0.125;
  static const dy = 0.125;
}

double _interpolateLinear({
  required Float32List values,
  required int x,
  required int y,
  required double xFraction,
  required double yFraction,
  required int nx,
  required bool longitudeWrap,
}) {
  final index = y * nx + x;
  final atEastEdge = !longitudeWrap && x >= nx - 1;
  final atSouthEdge = index + nx >= values.length;
  final nextIndex = longitudeWrap ? y * nx + ((x + 1) % nx) : index + 1;

  final p0 = values[index];
  if (atEastEdge && atSouthEdge) return p0.isFinite ? p0 : double.nan;
  if (atEastEdge) {
    final p2 = values[index + nx];
    if (p0.isFinite && p2.isFinite) {
      return p0 * (1 - yFraction) + p2 * yFraction;
    }
    return p0.isFinite ? p0 : double.nan;
  }
  if (atSouthEdge) {
    final p1 = values[nextIndex];
    if (p0.isFinite && p1.isFinite) {
      return p0 * (1 - xFraction) + p1 * xFraction;
    }
    return p0.isFinite ? p0 : double.nan;
  }

  final p1 = values[nextIndex];
  final p2 = values[index + nx];
  final p3 = values[nextIndex + nx];

  final w0 = (1 - xFraction) * (1 - yFraction);
  final w1 = xFraction * (1 - yFraction);
  final w2 = (1 - xFraction) * yFraction;
  final w3 = xFraction * yFraction;

  if (p0.isFinite && p1.isFinite && p2.isFinite && p3.isFinite) {
    return p0 * w0 + p1 * w1 + p2 * w2 + p3 * w3;
  }
  return double.nan;
}
