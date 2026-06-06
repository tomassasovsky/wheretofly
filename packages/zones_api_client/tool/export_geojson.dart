// Regenerates a GeoJSON FeatureCollection from the bundled zone snapshot, in
// the exact schema RemoteZonesApiClient expects.
//
// Usage (from the app root):
//   dart run packages/zones_api_client/tool/export_geojson.dart > feed/zones.geojson
import 'dart:convert';

import 'package:zones_api_client/zones_api_client.dart';

void main() {
  const client = BundledZonesApiClient();
  final features = client.zones
      .map(
        (z) => {
          'type': 'Feature',
          'properties': {
            'id': z.id,
            'name': z.name,
            'categoryId': z.categoryId,
            'latitude': z.latitude,
            'longitude': z.longitude,
            'radiusMeters': z.radiusMeters,
            'allowedPermissionIds': z.allowedPermissionIds.toList(),
            'details': z.details,
          },
          'geometry': _geometry(z),
        },
      )
      .toList();

  final featureCollection = {
    'type': 'FeatureCollection',
    'name': 'argentina_drone_zones',
    'features': features,
  };

  const encoder = JsonEncoder.withIndent('  ');
  // ignore: avoid_print
  print(encoder.convert(featureCollection));
}

/// Polygon geometry (closed ring) when the zone has a boundary, else a Point at
/// the bounding-circle centre. Mirrors the backend ingest schema.
Map<String, Object?> _geometry(ZoneData z) {
  final ring = z.polygon;
  if (ring == null || ring.length < 3) {
    return {
      'type': 'Point',
      'coordinates': [z.longitude, z.latitude],
    };
  }
  final closed = [for (final p in ring) [p[0], p[1]]];
  final first = closed.first;
  final last = closed.last;
  if (first[0] != last[0] || first[1] != last[1]) {
    closed.add([first[0], first[1]]);
  }
  return {
    'type': 'Polygon',
    'coordinates': [closed],
  };
}
