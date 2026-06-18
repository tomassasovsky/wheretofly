import 'dart:io';

import 'package:test/test.dart';
import 'package:zones_api_client/zones_api_client.dart';

void main() {
  late NotamParseResult result;

  setUpAll(() {
    final html = File('test/fixtures/notam_ef_sample.html').readAsStringSync();
    result = NotamParser.parse(html);
  });

  ZoneData zoneById(String id) => result.zones.firstWhere((z) => z.id == id);

  group('NotamParser real EANA fixture', () {
    test('parses the geocodable NOTAMs and lists the rest', () {
      // A1009 (polygon), A1177 + A1431 (circles) are drawable; A1980
      // (point-only obstacle) and A1935 (VOR outage, no geometry) are not.
      expect(result.zones, hasLength(3));
      expect(
        result.ungeocodable.map((n) => n.id),
        containsAll(['A1980/2026', 'A1935/2026']),
      );
      expect(
        result.ungeocodable.every((n) => n.summary.isNotEmpty),
        isTrue,
      );
      expect(
        result.zones.every((z) => z.source == ZoneSourceIds.notam),
        isTrue,
      );
    });

    test('parses a polygon NOTAM with validity and AGL ceiling', () {
      final zone = zoneById('notam_A1009_2026');
      expect(zone.name, 'NOTAM A1009/2026');
      expect(zone.polygon, hasLength(3));
      // 325431S/0604327W → -32.9086, -60.7242.
      expect(zone.polygon!.first[1], closeTo(-32.9086, 0.001)); // lat
      expect(zone.polygon!.first[0], closeTo(-60.7242, 0.001)); // lon
      // F) GND G) 400FT AGL
      expect(zone.lowerLimitMetersAgl, 0);
      expect(zone.upperLimitMetersAgl, closeTo(121.92, 0.1));
      expect(zone.activeFrom, DateTime.utc(2026, 3, 23, 10));
      expect(zone.activeFrom!.isUtc, isTrue);
      expect(zone.activeTo, DateTime.utc(2026, 6, 20, 23));
    });

    test('parses a circle NOTAM with RDO radius and FL ceiling', () {
      final zone = zoneById('notam_A1177_2026');
      expect(zone.polygon, isNull);
      // 385729S/0674813W, RDO 3NM → 3 * 1852 m.
      expect(zone.radiusMeters, closeTo(3 * 1852, 1));
      expect(zone.latitude, closeTo(-38.9581, 0.001));
      expect(zone.longitude, closeTo(-67.8036, 0.001));
      // GND FL120 → upper limit is MSL (FL120 = 12000 ft).
      expect(zone.lowerLimitMetersAgl, 0);
      expect(zone.upperLimitMetersMsl, closeTo(3657.6, 0.1));
    });

    test('every drawable NOTAM carries a validity window', () {
      expect(
        result.zones.every((z) => z.activeFrom != null && z.activeTo != null),
        isTrue,
      );
    });
  });

  group('NotamParser tolerance', () {
    test('returns empty result for non-table HTML', () {
      final result = NotamParser.parse('<html><body>nope</body></html>');
      expect(result.zones, isEmpty);
      expect(result.ungeocodable, isEmpty);
    });
  });
}
