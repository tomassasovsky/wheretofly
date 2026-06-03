import 'package:zones_api_client/src/models/zone_data.dart';

/// Common contract for runtime zone feeds (GeoJSON or backend API).
// ignore: one_member_abstracts
abstract class ZonesFeedClient {
  Future<List<ZoneData>> fetchZones();
}

/// Metadata from the last successful zone feed fetch.
class ZoneFeedMetadata {
  const ZoneFeedMetadata({
    this.version,
    this.updatedAt,
    this.etag,
  });

  final String? version;
  final DateTime? updatedAt;
  final String? etag;

  bool get isEmpty => version == null && updatedAt == null;
}
