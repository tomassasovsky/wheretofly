import 'package:flight_rules_repository/src/zone_deduplicator.dart';
import 'package:test/test.dart';
import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/zone_permission_ids.dart';

void main() {
  group('ZoneDeduplicator', () {
    test('keeps nested zones with different ids', () {
      const sar = ZoneData(
        id: 'openaip_sar01',
        name: 'SAR 01 Capital Federal',
        categoryId: 'restricted',
        latitude: -34.61,
        longitude: -58.36,
        radiusMeters: 20000,
        allowedPermissionIds: ZonePermissionIds.controlledAirspace,
        details: 'test',
      );
      const heliport = ZoneData(
        id: 'madhel_HMG',
        name: 'Madero Harbour',
        categoryId: 'controlled_airspace',
        latitude: -34.6105,
        longitude: -58.362,
        radiusMeters: 2000,
        allowedPermissionIds: ZonePermissionIds.controlledAirspace,
        details: 'test',
      );

      final deduped = ZoneDeduplicator.dedupe([heliport, sar]);
      expect(
        deduped.map((z) => z.id),
        containsAll(['openaip_sar01', 'madhel_HMG']),
      );
    });

    test('collapses duplicate ids and prefers higher-priority source', () {
      const bundled = ZoneData(
        id: 'madhel_AER',
        name: 'Bundled Aeroparque',
        categoryId: 'controlled_airspace',
        latitude: -34.55,
        longitude: -58.41,
        radiusMeters: 9000,
        allowedPermissionIds: ZonePermissionIds.controlledAirspace,
        details: 'bundled',
      );
      const live = ZoneData(
        id: 'madhel_AER',
        name: 'Live Aeroparque',
        categoryId: 'controlled_airspace',
        latitude: -34.559,
        longitude: -58.416,
        radiusMeters: 9000,
        allowedPermissionIds: ZonePermissionIds.controlledAirspace,
        details: 'live',
      );

      final deduped = ZoneDeduplicator.dedupe([bundled, live]);
      expect(deduped, hasLength(1));
      expect(deduped.single.name, 'Live Aeroparque');
    });

    test('keeps prohibited zone inside a larger restricted area', () {
      const sar = ZoneData(
        id: 'openaip_sar01',
        name: 'SAR 01',
        categoryId: 'restricted',
        latitude: -34.61,
        longitude: -58.36,
        radiusMeters: 20000,
        allowedPermissionIds: ZonePermissionIds.controlledAirspace,
        details: 'test',
      );
      const casaRosada = ZoneData(
        id: 'prohibited_casa_rosada',
        name: 'Casa Rosada',
        categoryId: 'prohibited',
        latitude: -34.608,
        longitude: -58.3702,
        radiusMeters: 700,
        allowedPermissionIds: {},
        details: 'test',
      );

      final deduped = ZoneDeduplicator.dedupe([sar, casaRosada]);
      expect(
        deduped.map((z) => z.id),
        containsAll(['openaip_sar01', 'prohibited_casa_rosada']),
      );
    });
  });
}
