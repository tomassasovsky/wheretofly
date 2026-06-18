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
  ///
  /// [aipZonesPath] is the path to the pre-generated ANAC AIP GeoJSON file
  /// produced by `tooling/anac_aip_parser`. When present its polygon zones
  /// override any matching id from the other sources (highest priority).
  ZoneIngestService({
    required Database database,
    required ZoneService zoneService,
    BundledZonesApiClient? bundled,
    MadhelZonesApiClient? madhel,
    OpenAipZonesApiClient? openaip,
    OpenAipExportZonesApiClient? openaipExport,
    this.aipZonesPath,
  }) : _db = database,
       _zoneService = zoneService,
       _bundled = bundled ?? const BundledZonesApiClient(),
       _madhel = madhel ?? MadhelZonesApiClient(),
       _openaip = openaip,
       _openaipExport = openaipExport ?? OpenAipExportZonesApiClient();

  final Database _db;
  final ZoneService _zoneService;
  final BundledZonesApiClient _bundled;
  final MadhelZonesApiClient _madhel;
  final OpenAipZonesApiClient? _openaip;
  final OpenAipExportZonesApiClient _openaipExport;

  /// Optional path to `anac_aip_zones.geojson` (from the parser tool).
  final String? aipZonesPath;

  /// Merges bundled, MADHEL, OpenAIP, and AIP-parsed zones, writes
  /// [outputPath], bumps version. AIP zones take highest precedence so their
  /// exact polygon boundaries win over any same-id circle approximations.
  Future<String> ingestAndPublish({required String outputPath}) async {
    final bundledZones = await _bundled.fetchZones();
    final liveMadhel = await _safeMadhel();
    final liveOpenAip = await _safeOpenAip();
    final aipZones = await _safeAipFile();

    // Merge order: bundled → MADHEL/OpenAIP → AIP polygons (highest wins).
    final merged = <String, ZoneData>{
      for (final zone in bundledZones) zone.id: zone,
    };
    for (final zone in [...liveMadhel, ...liveOpenAip]) {
      merged[zone.id] = zone;
    }
    for (final zone in aipZones) {
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
    // Centre/radius live in properties so the client always has the bounding
    // circle, independent of whether geometry is a Point or a Polygon.
    final properties = <String, Object?>{
      'id': zone.id,
      'name': zone.name,
      'categoryId': zone.categoryId,
      'latitude': zone.latitude,
      'longitude': zone.longitude,
      'radiusMeters': zone.radiusMeters,
      'allowedPermissionIds': zone.allowedPermissionIds.toList(),
      'details': zone.details,
      'source': zone.source,
    };
    _putIfNotNull(properties, 'lowerLimitMetersAgl', zone.lowerLimitMetersAgl);
    _putIfNotNull(properties, 'upperLimitMetersAgl', zone.upperLimitMetersAgl);
    _putIfNotNull(properties, 'lowerLimitMetersMsl', zone.lowerLimitMetersMsl);
    _putIfNotNull(properties, 'upperLimitMetersMsl', zone.upperLimitMetersMsl);
    if (zone.confirmedBy != null) properties['confirmedBy'] = zone.confirmedBy;
    if (zone.activeFrom != null) {
      properties['activeFrom'] = zone.activeFrom!.toUtc().toIso8601String();
    }
    if (zone.activeTo != null) {
      properties['activeTo'] = zone.activeTo!.toUtc().toIso8601String();
    }

    return {
      'type': 'Feature',
      'properties': properties,
      'geometry': _geometry(zone),
    };
  }

  /// Polygon geometry when the source supplied a real boundary ring (closed
  /// per the GeoJSON spec), otherwise a Point at the bounding-circle centre.
  Map<String, Object?> _geometry(ZoneData zone) {
    final ring = zone.polygon;
    if (ring == null || ring.length < 3) {
      return {
        'type': 'Point',
        'coordinates': [zone.longitude, zone.latitude],
      };
    }
    final closed = [
      for (final p in ring) [p[0], p[1]],
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
    final apiClient = _openaip;
    if (apiClient != null) {
      try {
        final fromApi = await apiClient.fetchZones();
        if (fromApi.isNotEmpty) return fromApi;
      } on Object {
        // Fall through to the daily country export.
      }
    }
    try {
      return await _openaipExport.fetchZones();
    } on Object {
      return const [];
    }
  }

  /// Reads and parses the pre-generated ANAC AIP GeoJSON file via the shared
  /// [AipGeoJsonReader] (which sets `source = aip` and repairs UTF-8 names).
  /// Returns an empty list if the file doesn't exist or cannot be parsed.
  Future<List<ZoneData>> _safeAipFile() async {
    final path = aipZonesPath;
    if (path == null) return const [];
    final file = File(path);
    if (!file.existsSync()) return const [];
    try {
      return const AipGeoJsonReader().parse(await file.readAsString());
    } on Object {
      return const [];
    }
  }
}
