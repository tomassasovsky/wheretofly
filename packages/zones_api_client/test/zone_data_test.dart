import 'package:test/test.dart';
import 'package:zones_api_client/zones_api_client.dart';

void main() {
  ZoneData base({
    String source = ZoneSourceIds.bundled,
    String? confirmedBy,
    DateTime? activeFrom,
    DateTime? activeTo,
  }) =>
      ZoneData(
        id: 'z1',
        name: 'Zone',
        categoryId: 'restricted',
        latitude: -34.6,
        longitude: -58.4,
        radiusMeters: 1000,
        allowedPermissionIds: const {'recreational'},
        details: 'x',
        source: source,
        confirmedBy: confirmedBy,
        activeFrom: activeFrom,
        activeTo: activeTo,
      );

  group('ZoneData provenance/validity', () {
    test('defaults to a bundled source with no confirmation or window', () {
      const zone = ZoneData(
        id: 'z1',
        name: 'Zone',
        categoryId: 'restricted',
        latitude: -34.6,
        longitude: -58.4,
        radiusMeters: 1000,
        allowedPermissionIds: {'recreational'},
        details: 'x',
      );

      expect(zone.source, ZoneSourceIds.bundled);
      expect(zone.confirmedBy, isNull);
      expect(zone.activeFrom, isNull);
      expect(zone.activeTo, isNull);
    });

    test('source is part of equality', () {
      expect(
        base(source: ZoneSourceIds.openaip),
        isNot(equals(base(source: ZoneSourceIds.aip))),
      );
    });

    test('confirmedBy and validity window are part of equality', () {
      final from = DateTime.utc(2026, 6, 18, 12);
      final to = DateTime.utc(2026, 6, 18, 18);
      expect(
        base(confirmedBy: ZoneSourceIds.aip, activeFrom: from, activeTo: to),
        equals(
          base(confirmedBy: ZoneSourceIds.aip, activeFrom: from, activeTo: to),
        ),
      );
      expect(
        base(activeFrom: from),
        isNot(equals(base(activeTo: to))),
      );
    });
  });

  group('ZoneSourceIds.fromIdPrefix', () {
    test('maps known prefixes to their source id', () {
      expect(ZoneSourceIds.fromIdPrefix('openaip_x'), ZoneSourceIds.openaip);
      expect(ZoneSourceIds.fromIdPrefix('madhel_x'), ZoneSourceIds.madhel);
      expect(ZoneSourceIds.fromIdPrefix('anac_sar_01'), ZoneSourceIds.aip);
      expect(ZoneSourceIds.fromIdPrefix('notam_x'), ZoneSourceIds.notam);
    });

    test('falls back to bundled for unknown prefixes', () {
      expect(ZoneSourceIds.fromIdPrefix('prohibited_x'), ZoneSourceIds.bundled);
      expect(ZoneSourceIds.fromIdPrefix(''), ZoneSourceIds.bundled);
    });
  });

  group('parseUtcDateTime', () {
    test('parses an ISO-8601 string and normalizes to UTC', () {
      final parsed = parseUtcDateTime('2026-06-18T15:00:00-03:00');
      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isTrue);
      expect(parsed, DateTime.utc(2026, 6, 18, 18));
    });

    test('returns null for missing or unparseable values', () {
      expect(parseUtcDateTime(null), isNull);
      expect(parseUtcDateTime(''), isNull);
      expect(parseUtcDateTime('not-a-date'), isNull);
      expect(parseUtcDateTime(42), isNull);
    });
  });
}
