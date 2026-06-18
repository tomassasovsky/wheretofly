import 'package:zones_api_client/zones_api_client.dart';

/// Typed provenance of a `FlyZone`: where its geometry originates and, via
/// `confirmedBy`, which authority confirms it.
///
/// The data layer carries provenance as a plain string id (`ZoneData.source`);
/// the repository resolves it to this enum in `_toFlyZone` with [fromId].
enum ZoneSource {
  /// ANAC AIP — the authoritative inventory of P/R/D areas.
  aip(id: ZoneSourceIds.aip),

  /// OpenAIP — the geometry baseline.
  openaip(id: ZoneSourceIds.openaip),

  /// EANA NOTAM — time-bounded temporary restrictions.
  notam(id: ZoneSourceIds.notam),

  /// ANAC MADHEL aerodrome/heliport catalog.
  madhel(id: ZoneSourceIds.madhel),

  /// Curated, manually-maintained bundled snapshot entries.
  bundled(id: ZoneSourceIds.bundled);

  const ZoneSource({required this.id});

  /// The canonical data-layer source id (see [ZoneSourceIds]).
  final String id;

  /// Resolves a [ZoneSource] from its [id], defaulting to [bundled] for an
  /// unknown or missing value.
  static ZoneSource fromId(String? id) => values.firstWhere(
        (s) => s.id == id,
        orElse: () => ZoneSource.bundled,
      );
}
