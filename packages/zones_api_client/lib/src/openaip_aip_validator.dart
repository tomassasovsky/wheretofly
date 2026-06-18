import 'dart:math' as math;

import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/zone_identity.dart';

/// Compares OpenAIP footprints against ANAC AIP reference polygons.
class OpenAipAipValidator {
  const OpenAipAipValidator();

  OpenAipAipValidationReport compare({
    required List<ZoneData> openAipZones,
    required List<ZoneData> aipZones,
  }) {
    final aipByKey = <String, ZoneData>{
      for (final zone in aipZones)
        if (ZoneIdentity.matchKey(zone.name) case final key?) key: zone,
    };

    final comparisons = <ZoneGeometryComparison>[];
    final unmatchedOpenAip = <ZoneData>[];
    final matchedAipKeys = <String>{};

    for (final openAip in openAipZones) {
      final key = ZoneIdentity.matchKey(openAip.name);
      if (key == null) {
        unmatchedOpenAip.add(openAip);
        continue;
      }
      final aip = aipByKey[key];
      if (aip == null) {
        unmatchedOpenAip.add(openAip);
        continue;
      }
      matchedAipKeys.add(key);
      comparisons.add(_compare(key: key, openAip: openAip, aip: aip));
    }

    final unmatchedAip = [
      for (final entry in aipByKey.entries)
        if (!matchedAipKeys.contains(entry.key)) entry.value,
    ];

    return OpenAipAipValidationReport(
      comparisons: comparisons,
      unmatchedOpenAip: unmatchedOpenAip,
      unmatchedAip: unmatchedAip,
    );
  }

  ZoneGeometryComparison _compare({
    required String key,
    required ZoneData openAip,
    required ZoneData aip,
  }) {
    final openRing = openAip.polygon ?? const <List<double>>[];
    final aipRing = aip.polygon ?? const <List<double>>[];
    final openArea = _ringAreaKm2(openRing);
    final aipArea = _ringAreaKm2(aipRing);
    final areaRatio = aipArea == 0 ? null : openArea / aipArea;

    final probes = _probePoints(openRing, aipRing);
    final onlyOpenAip = probes.where((p) => p.inOpenAip && !p.inAip).length;
    final onlyAip = probes.where((p) => p.inAip && !p.inOpenAip).length;

    final severity = _severity(
      areaRatio: areaRatio,
      onlyOpenAip: onlyOpenAip,
      onlyAip: onlyAip,
      openVertices: openRing.length,
      aipVertices: aipRing.length,
    );

    return ZoneGeometryComparison(
      key: key,
      openAipName: openAip.name,
      aipName: aip.name,
      openAipId: openAip.id,
      aipId: aip.id,
      openAipAreaKm2: openArea,
      aipAreaKm2: aipArea,
      areaRatio: areaRatio,
      openAipVertices: openRing.length,
      aipVertices: aipRing.length,
      probePointsOnlyOpenAip: onlyOpenAip,
      probePointsOnlyAip: onlyAip,
      severity: severity,
    );
  }

  static ZoneMismatchSeverity _severity({
    required double? areaRatio,
    required int onlyOpenAip,
    required int onlyAip,
    required int openVertices,
    required int aipVertices,
  }) {
    if (areaRatio == null) return ZoneMismatchSeverity.major;
    final ratioFar = areaRatio < 0.5 || areaRatio > 2.0;
    final shapeFar = onlyOpenAip >= 2 || onlyAip >= 2;
    if (ratioFar || shapeFar) {
      return ZoneMismatchSeverity.major;
    }
    if (areaRatio < 0.8 || areaRatio > 1.25 || onlyOpenAip > 0 || onlyAip > 0) {
      return ZoneMismatchSeverity.review;
    }
    return ZoneMismatchSeverity.ok;
  }

  static double _ringAreaKm2(List<List<double>> ring) {
    if (ring.length < 3) return 0;
    var area = 0.0;
    for (var i = 0; i < ring.length; i++) {
      final j = (i + 1) % ring.length;
      final xi = ring[i][0] * math.cos(ring[i][1] * math.pi / 180);
      final yi = ring[i][1];
      final xj = ring[j][0] * math.cos(ring[j][1] * math.pi / 180);
      final yj = ring[j][1];
      area += xi * yj - xj * yi;
    }
    return (area.abs() / 2) * 111 * 111;
  }

  static List<_Probe> _probePoints(
    List<List<double>> openRing,
    List<List<double>> aipRing,
  ) {
    final points = <_Probe>[];
    final rings = [openRing, aipRing].where((ring) => ring.length >= 3);
    if (rings.isEmpty) return points;

    final lats = rings.expand((ring) => ring.map((p) => p[1]));
    final lons = rings.expand((ring) => ring.map((p) => p[0]));
    final minLat = lats.reduce(math.min);
    final maxLat = lats.reduce(math.max);
    final minLon = lons.reduce(math.min);
    final maxLon = lons.reduce(math.max);
    final midLat = (minLat + maxLat) / 2;
    final midLon = (minLon + maxLon) / 2;

    for (final lat in [minLat, midLat, maxLat]) {
      for (final lon in [minLon, midLon, maxLon]) {
        points.add(
          _Probe(
            lat: lat,
            lon: lon,
            inOpenAip: _pointInRing(lat, lon, openRing),
            inAip: _pointInRing(lat, lon, aipRing),
          ),
        );
      }
    }
    return points;
  }

  static bool _pointInRing(double lat, double lon, List<List<double>> ring) {
    if (ring.length < 3) return false;
    final x = lon;
    final y = lat;
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i][0];
      final yi = ring[i][1];
      final xj = ring[j][0];
      final yj = ring[j][1];
      final intersects = (yi > y) != (yj > y) &&
          x < (xj - xi) * (y - yi) / (yj - yi + 1e-30) + xi;
      if (intersects) inside = !inside;
    }
    return inside;
  }
}

enum ZoneMismatchSeverity { ok, review, major }

class OpenAipAipValidationReport {
  const OpenAipAipValidationReport({
    required this.comparisons,
    required this.unmatchedOpenAip,
    required this.unmatchedAip,
  });

  final List<ZoneGeometryComparison> comparisons;
  final List<ZoneData> unmatchedOpenAip;
  final List<ZoneData> unmatchedAip;

  List<ZoneGeometryComparison> get majorMismatches => comparisons
      .where((c) => c.severity == ZoneMismatchSeverity.major)
      .toList(growable: false);

  List<ZoneGeometryComparison> get reviewMismatches => comparisons
      .where((c) => c.severity == ZoneMismatchSeverity.review)
      .toList(growable: false);
}

class ZoneGeometryComparison {
  const ZoneGeometryComparison({
    required this.key,
    required this.openAipName,
    required this.aipName,
    required this.openAipId,
    required this.aipId,
    required this.openAipAreaKm2,
    required this.aipAreaKm2,
    required this.areaRatio,
    required this.openAipVertices,
    required this.aipVertices,
    required this.probePointsOnlyOpenAip,
    required this.probePointsOnlyAip,
    required this.severity,
  });

  final String key;
  final String openAipName;
  final String aipName;
  final String openAipId;
  final String aipId;
  final double openAipAreaKm2;
  final double aipAreaKm2;
  final double? areaRatio;
  final int openAipVertices;
  final int aipVertices;
  final int probePointsOnlyOpenAip;
  final int probePointsOnlyAip;
  final ZoneMismatchSeverity severity;
}

class _Probe {
  const _Probe({
    required this.lat,
    required this.lon,
    required this.inOpenAip,
    required this.inAip,
  });

  final double lat;
  final double lon;
  final bool inOpenAip;
  final bool inAip;
}
