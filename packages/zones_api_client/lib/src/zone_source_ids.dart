/// Canonical provenance source ids used in the data layer.
///
/// These are plain strings (like `ZoneData.categoryId`) so the DTO stays
/// primitive and serializes directly into the zone feed. The repository maps
/// them to a typed `ZoneSource` enum.
abstract final class ZoneSourceIds {
  /// ANAC AIP (authoritative inventory of P/R/D areas).
  static const aip = 'aip';

  /// OpenAIP export / REST API (geometry baseline).
  static const openaip = 'openaip';

  /// ANAC MADHEL aerodrome/heliport catalog.
  static const madhel = 'madhel';

  /// EANA NOTAM (time-bounded temporary restrictions).
  static const notam = 'notam';

  /// Curated, manually-maintained bundled snapshot entries.
  static const bundled = 'bundled';

  /// Best-effort source id derived from a zone id prefix, used only as a
  /// fallback for feeds that predate the explicit `source` property. New
  /// producers always set `ZoneData.source` directly.
  static String fromIdPrefix(String id) {
    if (id.startsWith('openaip_')) return openaip;
    if (id.startsWith('madhel_')) return madhel;
    if (id.startsWith('anac_')) return aip;
    if (id.startsWith('notam_')) return notam;
    return bundled;
  }
}
