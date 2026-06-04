import 'dart:convert';
import 'dart:io';

import 'package:backend/db/database.dart';
import 'package:backend/services/zone_service.dart';
import 'package:postgres/postgres.dart';
import 'package:zones_api_client/zones_api_client.dart';

/// Refreshes the published zone GeoJSON feed from bundled + live external
/// feeds.
class ZoneIngestService {
  /// Creates an ingest pipeline with optional zone source clients.
  ZoneIngestService({
    required Database database,
    required ZoneService zoneService,
    BundledZonesApiClient? bundled,
    MadhelZonesApiClient? madhel,
    OpenAipZonesApiClient? openaip,
  }) : _db = database,
       _zoneService = zoneService,
       _bundled = bundled ?? const BundledZonesApiClient(),
       _madhel = madhel ?? MadhelZonesApiClient(),
       _openaip = openaip;

  final Database _db;
  final ZoneService _zoneService;
  final BundledZonesApiClient _bundled;
  final MadhelZonesApiClient _madhel;
  final OpenAipZonesApiClient? _openaip;

  /// Merges bundled, MADHEL, and OpenAIP zones, writes [outputPath], bumps
  /// version.
  Future<String> ingestAndPublish({required String outputPath}) async {
    final bundledZones = await _bundled.fetchZones();
    final liveMadhel = await _safeMadhel();
    final liveOpenAip = await _safeOpenAip();
    final merged = <String, ZoneData>{
      for (final zone in bundledZones) zone.id: zone,
    };
    for (final zone in [...liveMadhel, ...liveOpenAip]) {
      merged[zone.id] = zone;
    }

    final features = merged.values.map(_toFeature).toList();

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

  Map<String, Object?> _toFeature(ZoneData zone) {
    final properties = <String, Object?>{
      'id': zone.id,
      'name': zone.name,
      'categoryId': zone.categoryId,
      'radiusMeters': zone.radiusMeters,
      'allowedPermissionIds': zone.allowedPermissionIds.toList(),
      'details': zone.details,
    };
    _putIfNotNull(properties, 'lowerLimitMetersAgl', zone.lowerLimitMetersAgl);
    _putIfNotNull(properties, 'upperLimitMetersAgl', zone.upperLimitMetersAgl);
    _putIfNotNull(properties, 'lowerLimitMetersMsl', zone.lowerLimitMetersMsl);
    _putIfNotNull(properties, 'upperLimitMetersMsl', zone.upperLimitMetersMsl);

    return {
      'type': 'Feature',
      'properties': properties,
      'geometry': {
        'type': 'Point',
        'coordinates': [zone.longitude, zone.latitude],
      },
    };
  }

  void _putIfNotNull(
    Map<String, Object?> target,
    String key,
    double? value,
  ) {
    if (value != null) target[key] = value;
  }

  Future<List<ZoneData>> _safeMadhel() async {
    try {
      return await _madhel.fetchZones();
    } on Object {
      return const [];
    }
  }

  Future<List<ZoneData>> _safeOpenAip() async {
    final client = _openaip;
    if (client == null) return const [];
    try {
      return await client.fetchZones();
    } on Object {
      return const [];
    }
  }
}
