// Generates backend/data/anac_aip_zones.geojson from the hardcoded AIP
// boundary database.
//
// Usage (from repo root):
//   cd tooling/anac_aip_parser && dart pub get
//   dart run tooling/anac_aip_parser/bin/generate_zones.dart
//
// Or write directly:
//   dart run tooling/anac_aip_parser/bin/generate_zones.dart \
//     --out ../../backend/data/anac_aip_zones.geojson

import 'dart:convert';
import 'dart:io';
import 'dart:math' show asin, cos, sin, sqrt;

import 'package:anac_aip_parser/anac_aip_parser.dart';

void main(List<String> args) {
  final outArg = _parseOut(args);

  final parser = BoundaryParser();
  const densifier = ArcDensifier(arcStepDeg: 0.5);

  final features = <Map<String, Object?>>[];
  var ok = 0;
  var failed = 0;

  for (final entry in zoneDatabase) {
    final result = parser.parse(entry.boundaryText);
    if (result == null) {
      stderr.writeln('[WARN] no coordinates found: ${entry.id}');
      failed++;
      continue;
    }

    final (start, segments) = result;
    final ring = densifier.densify(start, segments);

    if (ring.length < 4) {
      stderr.writeln('[WARN] degenerate ring (${ring.length} pts): ${entry.id}');
      failed++;
      continue;
    }

    // Bounding-circle centre: arithmetic mean of ring vertices.
    final lat =
        ring.map((p) => p[1]).reduce((a, b) => a + b) / ring.length;
    final lon =
        ring.map((p) => p[0]).reduce((a, b) => a + b) / ring.length;

    // Enclosing radius via max haversine from centre.
    final radiusM = ring
        .map((p) => _haversine(lat, lon, p[1], p[0]))
        .reduce((a, b) => a > b ? a : b);

    final props = <String, Object?>{
      'id': entry.id,
      'name': entry.name,
      'categoryId': entry.categoryId,
      'latitude': lat,
      'longitude': lon,
      'radiusMeters': radiusM,
      'allowedPermissionIds': entry.allowedPermissionIds.toList(),
      'details': entry.details,
      'source': 'ANAC AIP',
    };
    _putNN(props, 'lowerLimitMetersAgl', entry.lowerLimitMetersAgl);
    _putNN(props, 'upperLimitMetersAgl', entry.upperLimitMetersAgl);
    _putNN(props, 'lowerLimitMetersMsl', entry.lowerLimitMetersMsl);
    _putNN(props, 'upperLimitMetersMsl', entry.upperLimitMetersMsl);

    features.add({
      'type': 'Feature',
      'properties': props,
      'geometry': {
        'type': 'Polygon',
        'coordinates': [ring],
      },
    });

    stderr.writeln('[OK]  ${entry.id} — ${ring.length} vertices');
    ok++;
  }

  final collection = {
    'type': 'FeatureCollection',
    'name': 'anac_aip_zones',
    'generated': DateTime.now().toUtc().toIso8601String(),
    'note': 'Parsed from ANAC Argentina AIP. Verify against current AIRAC.',
    'features': features,
  };

  final json = const JsonEncoder.withIndent('  ').convert(collection);

  if (outArg != null) {
    final f = File(outArg);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(json);
    stderr.writeln('\nWrote $outArg  ($ok zones, $failed skipped)');
  } else {
    stdout.writeln(json);
    stderr.writeln('\n$ok zones generated, $failed skipped');
  }

  if (failed > 0) exitCode = 1;
}

String? _parseOut(List<String> args) {
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i] == '--out' || args[i] == '-o') return args[i + 1];
  }
  return null;
}

void _putNN(Map<String, Object?> m, String k, double? v) {
  if (v != null) m[k] = v;
}

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  const toRad = 3.14159265358979 / 180;
  final dLat = (lat2 - lat1) * toRad;
  final dLon = (lon2 - lon1) * toRad;
  final a = _sq(sin(dLat / 2)) +
      cos(lat1 * toRad) * cos(lat2 * toRad) * _sq(sin(dLon / 2));
  return r * 2 * asin(sqrt(a > 1 ? 1 : a));
}

double _sq(double x) => x * x;
