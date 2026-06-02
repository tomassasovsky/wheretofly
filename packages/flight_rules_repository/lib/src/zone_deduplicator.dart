import 'package:zones_api_client/zones_api_client.dart';

/// Removes literal duplicate zone records after merging feeds.
///
/// Only collapses entries that share the same [ZoneData.id]. Geographic
/// containment (a smaller zone inside a larger one) is never treated as a
/// duplicate.
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

    return zones.map((zone) => zone.id).toSet().map((id) => byId[id]!).toList();
  }

  static int _sourcePriority(ZoneData zone) {
    if (zone.id.startsWith('openaip_')) return 40;
    if (zone.id.startsWith('prohibited_') ||
        zone.id.startsWith('military_') ||
        zone.id.startsWith('park_') ||
        zone.id.startsWith('infra_')) {
      return 30;
    }
    if (zone.id.startsWith('madhel_')) return 10;
    return 20;
  }
}
