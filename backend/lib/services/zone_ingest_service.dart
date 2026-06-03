import 'dart:convert';
import 'dart:io';

import 'package:backend/db/database.dart';
import 'package:backend/services/zone_service.dart';
import 'package:postgres/postgres.dart';
import 'package:zones_api_client/zones_api_client.dart';

/// Refreshes the published zone GeoJSON feed from bundled + live MADHEL data.
class ZoneIngestService {
  /// Creates an ingest pipeline with optional zone source clients.
  ZoneIngestService({
    required Database database,
    required ZoneService zoneService,
    BundledZonesApiClient? bundled,
    MadhelZonesApiClient? madhel,
  }) : _db = database,
       _zoneService = zoneService,
       _bundled = bundled ?? const BundledZonesApiClient(),
       _madhel = madhel ?? MadhelZonesApiClient();

  final Database _db;
  final ZoneService _zoneService;
  final BundledZonesApiClient _bundled;
  final MadhelZonesApiClient _madhel;

  /// Merges bundled and live zones, writes [outputPath], and bumps version.
  Future<String> ingestAndPublish({required String outputPath}) async {
    final bundledZones = await _bundled.fetchZones();
    final liveMadhel = await _safeMadhel();
    final merged = <String, ZoneData>{
      for (final zone in bundledZones) zone.id: zone,
    };
    for (final zone in liveMadhel) {
      merged[zone.id] = zone;
    }

    final features = merged.values
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

    final version = DateTime.now().toUtc().toIso8601String();
    final collection = {
      'type': 'FeatureCollection',
      'name': 'argentina_drone_zones',
      'version': version,
      'features': features,
    };
    const encoder = JsonEncoder.withIndent('  ');
    final body = encoder.convert(collection);

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(body);

    await _zoneService.updateFeedVersion(version);
    await _db.connection.execute(
      Sql.named('''
        UPDATE zone_feed_meta
        SET version = @version, updated_at = NOW()
        WHERE id = 1
      '''),
      parameters: {'version': version},
    );

    return version;
  }

  Future<List<ZoneData>> _safeMadhel() async {
    try {
      return await _madhel.fetchZones();
    } on Object {
      return const [];
    }
  }
}
