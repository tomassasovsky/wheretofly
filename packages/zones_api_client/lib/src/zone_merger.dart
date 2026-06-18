import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/zone_identity.dart';
import 'package:zones_api_client/src/zone_source_ids.dart';

/// Collapses zones that two sources describe as the same real airspace.
///
/// ANAC AIP is the authoritative **inventory**; OpenAIP is the **geometry**
/// baseline. When an OpenAIP zone and an AIP zone share a
/// [ZoneIdentity.matchKey], they should render **once**: OpenAIP's vertex-exact
/// geometry carrying AIP-confirmed identity, category, permissions, and
/// vertical limits (`source = openaip`, `confirmedBy = aip`).
///
/// Safety contract:
/// - A `matchKey` **miss** (no cross-source partner, or `null` key) keeps the
///   zone unchanged — a double-render is safer than a dropped authoritative
///   zone (the validator flags the overlap).
/// - A `matchKey` **collision between two distinct designators** is a
///   `matchKey` bug, caught by a test over the known designators — not guarded
///   here at runtime.
///
/// Both the backend `ZoneIngestService` merge step and the repository
/// `ZoneDeduplicator` delegate here so the merge rule lives in exactly one
/// place.
abstract final class ZoneMerger {
  /// Returns [zones] with each AIP+OpenAIP `matchKey` pair collapsed to a
  /// single merged zone. Input order is otherwise preserved.
  static List<ZoneData> merge(List<ZoneData> zones) {
    if (zones.length < 2) return zones;

    // Group indices by matchKey so we can collapse a group in place while
    // leaving keyless / unpaired zones exactly where they were.
    final indicesByKey = <String, List<int>>{};
    for (var i = 0; i < zones.length; i++) {
      final key = ZoneIdentity.matchKey(zones[i].name);
      if (key == null) continue;
      (indicesByKey[key] ??= []).add(i);
    }

    // For each collapsible group, record the surviving merged zone at the
    // OpenAIP zone's slot and the index to drop (the matched AIP zone).
    final mergedAt = <int, ZoneData>{};
    final dropped = <int>{};
    for (final indices in indicesByKey.values) {
      if (indices.length < 2) continue;

      int? openIndex; // first OpenAIP zone in the group
      int? openPolygonIndex; // first OpenAIP zone carrying a real polygon
      int? aipIndex; // first AIP zone in the group
      for (final i in indices) {
        final zone = zones[i];
        if (zone.source == ZoneSourceIds.openaip) {
          openIndex ??= i;
          if (openPolygonIndex == null && (zone.polygon?.length ?? 0) >= 3) {
            openPolygonIndex = i;
          }
        } else if (zone.source == ZoneSourceIds.aip) {
          aipIndex ??= i;
        }
      }

      final geometryIndex = openPolygonIndex ?? openIndex;
      if (geometryIndex == null || aipIndex == null) continue;
      mergedAt[geometryIndex] = _collapse(
        openAip: zones[geometryIndex],
        aip: zones[aipIndex],
      );
      dropped.add(aipIndex);
    }

    if (mergedAt.isEmpty) return zones;

    final result = <ZoneData>[];
    for (var i = 0; i < zones.length; i++) {
      if (dropped.contains(i)) continue;
      result.add(mergedAt[i] ?? zones[i]);
    }
    return result;
  }

  /// OpenAIP geometry combined with AIP authority: identity, category,
  /// permissions, and vertical limits.
  static ZoneData _collapse({
    required ZoneData openAip,
    required ZoneData aip,
  }) =>
      ZoneData(
        id: openAip.id,
        name: aip.name,
        categoryId: aip.categoryId,
        latitude: openAip.latitude,
        longitude: openAip.longitude,
        radiusMeters: openAip.radiusMeters,
        polygon: openAip.polygon,
        allowedPermissionIds: aip.allowedPermissionIds,
        details: aip.details,
        lowerLimitMetersAgl: aip.lowerLimitMetersAgl,
        upperLimitMetersAgl: aip.upperLimitMetersAgl,
        lowerLimitMetersMsl: aip.lowerLimitMetersMsl,
        upperLimitMetersMsl: aip.upperLimitMetersMsl,
        source: ZoneSourceIds.openaip,
        confirmedBy: ZoneSourceIds.aip,
      );
}
