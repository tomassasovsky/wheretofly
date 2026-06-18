import 'dart:convert';
import 'dart:io';

import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/text_encoding.dart';
import 'package:zones_api_client/src/zone_source_ids.dart';

/// Reads ANAC AIP zone polygons produced by `tooling/anac_aip_parser`.
class AipGeoJsonReader {
  const AipGeoJsonReader();

  Future<List<ZoneData>> readFile(String path) async {
    final body = await File(path).readAsString();
    return parse(body);
  }

  List<ZoneData> parse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];
    final features = decoded['features'];
    if (features is! List) return const [];

    return [
      for (final feature in features.whereType<Map<String, dynamic>>())
        if (_parseFeature(feature) case final zone?) zone,
    ];
  }

  ZoneData? _parseFeature(Map<String, dynamic> feature) {
    final props = feature['properties'];
    final geometry = feature['geometry'];
    if (props is! Map<String, dynamic> || geometry is! Map<String, dynamic>) {
      return null;
    }

    final polygon = _parsePolygon(geometry);
    final lat = _d(props['latitude']);
    final lon = _d(props['longitude']);
    if (lat == null || lon == null) return null;

    final permissions = (props['allowedPermissionIds'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        const <String>{};

    return ZoneData(
      id: (props['id'] ?? '').toString(),
      name: repairUtf8Text((props['name'] ?? '').toString()),
      categoryId: (props['categoryId'] ?? 'restricted').toString(),
      latitude: lat,
      longitude: lon,
      radiusMeters: _d(props['radiusMeters']) ?? 3000,
      polygon: polygon,
      allowedPermissionIds: permissions,
      details: repairUtf8Text((props['details'] ?? '').toString()),
      lowerLimitMetersAgl: _d(props['lowerLimitMetersAgl']),
      upperLimitMetersAgl: _d(props['upperLimitMetersAgl']),
      lowerLimitMetersMsl: _d(props['lowerLimitMetersMsl']),
      upperLimitMetersMsl: _d(props['upperLimitMetersMsl']),
      source: ZoneSourceIds.aip,
    );
  }

  List<List<double>>? _parsePolygon(Map<String, dynamic> geometry) {
    if (geometry['type'] != 'Polygon') return null;
    final coords = geometry['coordinates'];
    if (coords is! List || coords.isEmpty) return null;
    final ring = coords.first;
    if (ring is! List || ring.length < 3) return null;
    final out = <List<double>>[];
    for (final p in ring) {
      if (p is List && p.length >= 2) {
        out.add([(p[0] as num).toDouble(), (p[1] as num).toDouble()]);
      }
    }
    return out.length < 3 ? null : out;
  }

  double? _d(Object? v) => v == null ? null : (v as num).toDouble();
}
