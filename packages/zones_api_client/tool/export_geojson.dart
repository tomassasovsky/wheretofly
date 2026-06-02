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
            'radiusMeters': z.radiusMeters,
            'allowedPermissionIds': z.allowedPermissionIds.toList(),
            'details': z.details,
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [z.longitude, z.latitude],
          },
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
