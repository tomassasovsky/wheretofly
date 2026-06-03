import 'dart:io';

import 'package:backend/config/app_config.dart';
import 'package:backend/db/database.dart';
import 'package:postgres/postgres.dart';

/// Serves the zone GeoJSON feed with versioning metadata.
class ZoneService {
  /// Creates a zone feed service bound to [database] and [config].
  ZoneService({required Database database, required AppConfig config})
    : _db = database,
      _config = config;

  final Database _db;
  final AppConfig _config;

  /// Returns the zone feed or a 304-style not-modified response.
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

  /// Persists a new feed [version] after ingest or manual publish.
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

/// Result of a zone feed read, including conditional GET metadata.
class ZoneFeedResponse {
  /// Creates a full feed response with GeoJSON body.
  const ZoneFeedResponse({
    required this.etag,
    required this.version,
    required this.updatedAt,
    required this.geojson,
    required this.notModified,
  });

  /// Builds a not-modified response when ETags match.
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

  /// Builds an empty feature collection when the feed file is missing.
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

  /// ETag value clients may send as `If-None-Match`.
  final String etag;

  /// Published feed version string.
  final String version;

  /// Last time the feed metadata was updated.
  final DateTime updatedAt;

  /// GeoJSON feature collection body (empty when not modified).
  final String geojson;

  /// True when the client already has the current feed.
  final bool notModified;
}
