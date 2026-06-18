// Regenerates a GeoJSON FeatureCollection from bundled + live MADHEL + OpenAIP
// export, in the schema RemoteZonesApiClient expects.
//
// Usage (from the app root):
//   dart run packages/zones_api_client/tool/export_geojson.dart > feed/zones.geojson
import 'dart:convert';
import 'dart:io';

import 'package:zones_api_client/zones_api_client.dart';

Future<void> main() async {
  const bundled = BundledZonesApiClient();
  final madhel = await _safe(() => MadhelZonesApiClient().fetchZones());
  final openaip = await _safe(() => OpenAipExportZonesApiClient().fetchZones());

  final merged = <String, ZoneData>{
    for (final zone in bundled.zones) zone.id: zone,
    for (final zone in madhel) zone.id: zone,
    for (final zone in openaip) zone.id: zone,
  }.values.toList();

  final features = merged
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
            if (z.lowerLimitMetersAgl != null)
              'lowerLimitMetersAgl': z.lowerLimitMetersAgl,
            if (z.upperLimitMetersAgl != null)
              'upperLimitMetersAgl': z.upperLimitMetersAgl,
            if (z.lowerLimitMetersMsl != null)
              'lowerLimitMetersMsl': z.lowerLimitMetersMsl,
            if (z.upperLimitMetersMsl != null)
              'upperLimitMetersMsl': z.upperLimitMetersMsl,
          },
          'geometry': _geometry(z),
        },
      )
      .toList();

  final featureCollection = {
    'type': 'FeatureCollection',
    'name': 'argentina_drone_zones',
    'version': DateTime.now().toUtc().toIso8601String(),
    'features': features,
  };

  const encoder = JsonEncoder.withIndent('  ');
  // ignore: avoid_print
  print(encoder.convert(featureCollection));
}

Future<List<ZoneData>> _safe(
  Future<List<ZoneData>> Function() fetch,
) async {
  try {
    return await fetch();
  } on Object {
    stderr.writeln('Warning: zone source failed, continuing without it.');
    return const [];
  }
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
  final closed = [
    for (final p in ring) [p[0], p[1]]
  ];
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
