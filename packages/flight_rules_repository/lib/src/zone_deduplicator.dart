import 'package:zones_api_client/zones_api_client.dart';

/// Removes duplicate zone records after merging feeds.
///
/// Two passes: first collapse literal [ZoneData.id] duplicates (the
/// highest-priority source wins), then delegate to [ZoneMerger] to collapse
/// cross-source AIP+OpenAIP pairs that describe the same airspace under
/// different ids. Geographic containment (a smaller zone inside a larger one)
/// is never treated as a duplicate.
abstract final class ZoneDeduplicator {
  static List<ZoneData> dedupe(List<ZoneData> zones) {
    if (zones.length < 2) return zones;

    final byId = <String, ZoneData>{};
    for (final zone in zones) {
      final existing = byId[zone.id];
      if (existing == null ||
          _sourcePriority(zone) >= _sourcePriority(existing)) {
        byId[zone.id] = zone;
      }
    }

    final byIdDeduped =
        zones.map((zone) => zone.id).toSet().map((id) => byId[id]!).toList();
    return ZoneMerger.merge(byIdDeduped);
  }

  /// When two records share an id, the higher-priority source wins. An active
  /// temporary NOTAM restriction ranks highest for safety; below it OpenAIP
  /// (vertex-exact geometry) outranks AIP, then curated/bundled; live MADHEL
  /// ranks lowest so a same-id curated override or a real polygon takes
  /// precedence over a plain aerodrome circle.
  static int _sourcePriority(ZoneData zone) => switch (zone.source) {
        ZoneSourceIds.notam => 50,
        ZoneSourceIds.openaip => 40,
        ZoneSourceIds.aip => 35,
        ZoneSourceIds.bundled => 30,
        ZoneSourceIds.madhel => 10,
        _ => 20,
      };
}
