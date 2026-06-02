import 'dart:io';

import 'package:backend/config/app_config.dart';
import 'package:backend/db/database.dart';
import 'package:postgres/postgres.dart';

/// Serves the zone GeoJSON feed with versioning metadata.
class ZoneService {
  ZoneService({required Database database, required AppConfig config})
    : _db = database,
      _config = config;

  final Database _db;
  final AppConfig _config;

  Future<ZoneFeedResponse> getFeed({String? ifNoneMatch}) async {
    final meta = await _db.connection.execute(
      'SELECT version, updated_at FROM zone_feed_meta WHERE id = 1',
    );
    final version = meta.isEmpty ? 'bundled-v1' : meta.first[0]! as String;
    final updatedAt = meta.isEmpty
        ? DateTime.now()
        : meta.first[1]! as DateTime;
    final etag = '"$version"';
    if (ifNoneMatch == etag) {
      return ZoneFeedResponse.notModified(etag: etag, version: version);
    }
    final file = File(_config.zoneFeedPath);
    if (!file.existsSync()) {
      return ZoneFeedResponse.empty(etag: etag, version: version);
    }
    final geojson = await file.readAsString();
    return ZoneFeedResponse(
      etag: etag,
      version: version,
      updatedAt: updatedAt,
      geojson: geojson,
      notModified: false,
    );
  }

  Future<void> updateFeedVersion(String version) async {
    await _db.connection.execute(
      Sql.named('''
        UPDATE zone_feed_meta
        SET version = @version, updated_at = NOW()
        WHERE id = 1
      '''),
      parameters: {'version': version},
    );
  }
}

class ZoneFeedResponse {
  const ZoneFeedResponse({
    required this.etag,
    required this.version,
    required this.updatedAt,
    required this.geojson,
    required this.notModified,
  });

  factory ZoneFeedResponse.notModified({
    required String etag,
    required String version,
  }) {
    return ZoneFeedResponse(
      etag: etag,
      version: version,
      updatedAt: DateTime.now(),
      geojson: '',
      notModified: true,
    );
  }

  factory ZoneFeedResponse.empty({
    required String etag,
    required String version,
  }) {
    return ZoneFeedResponse(
      etag: etag,
      version: version,
      updatedAt: DateTime.now(),
      geojson: '{"type":"FeatureCollection","features":[]}',
      notModified: false,
    );
  }

  final String etag;
  final String version;
  final DateTime updatedAt;
  final String geojson;
  final bool notModified;
}
