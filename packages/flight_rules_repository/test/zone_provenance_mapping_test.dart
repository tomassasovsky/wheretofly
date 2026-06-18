import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:test/test.dart';
import 'package:zones_api_client/zones_api_client.dart';

void main() {
  group('FlightRulesRepository provenance mapping', () {
    test('maps source/confirmedBy ids to ZoneSource and passes validity', () {
      final from = DateTime.utc(2026, 6, 18, 12);
      final to = DateTime.utc(2026, 6, 18, 18);
      final repo = FlightRulesRepository.fromZoneData([
        ZoneData(
          id: 'notam_z1',
          name: 'Temporary',
          categoryId: 'restricted',
          latitude: -34.6,
          longitude: -58.4,
          radiusMeters: 2000,
          allowedPermissionIds: const {},
          details: 'x',
          source: ZoneSourceIds.openaip,
          confirmedBy: ZoneSourceIds.aip,
          activeFrom: from,
          activeTo: to,
        ),
      ]);

      final zone = repo.zones.single;
      expect(zone.source, ZoneSource.openaip);
      expect(zone.confirmedBy, ZoneSource.aip);
      expect(zone.activeFrom, from);
      expect(zone.activeTo, to);
    });

    test('defaults confirmedBy to null when the data layer has none', () {
      final repo = FlightRulesRepository.fromZoneData([
        const ZoneData(
          id: 'z1',
          name: 'Zone',
          categoryId: 'restricted',
          latitude: -34.6,
          longitude: -58.4,
          radiusMeters: 2000,
          allowedPermissionIds: {},
          details: 'x',
          source: ZoneSourceIds.aip,
        ),
      ]);

      final zone = repo.zones.single;
      expect(zone.source, ZoneSource.aip);
      expect(zone.confirmedBy, isNull);
    });
  });
}
