import 'package:test/test.dart';
import 'package:zones_api_client/zones_api_client.dart';

void main() {
  ZoneData openAip({
    required String id,
    required String name,
    String categoryId = 'controlled_airspace',
    List<List<double>>? polygon,
  }) =>
      ZoneData(
        id: id,
        name: name,
        categoryId: categoryId,
        latitude: -34.82,
        longitude: -58.53,
        radiusMeters: 15000,
        polygon: polygon ??
            const [
              [-58.6, -34.9],
              [-58.4, -34.9],
              [-58.4, -34.7],
              [-58.6, -34.7],
            ],
        allowedPermissionIds: const {'controlled'},
        details: 'OpenAIP geometry',
        source: ZoneSourceIds.openaip,
      );

  ZoneData aip({
    required String id,
    required String name,
    String categoryId = 'restricted',
    Set<String> permissions = const {'special_permit'},
    double? lowerAgl,
  }) =>
      ZoneData(
        id: id,
        name: name,
        categoryId: categoryId,
        latitude: -34.81,
        longitude: -58.52,
        radiusMeters: 14000,
        allowedPermissionIds: permissions,
        details: 'AIP authority',
        lowerLimitMetersAgl: lowerAgl,
        source: ZoneSourceIds.aip,
      );

  group('ZoneMerger.merge', () {
    test('collapses an AIP+OpenAIP pair into one merged zone', () {
      final result = ZoneMerger.merge([
        openAip(id: 'openaip_eze', name: 'EZEIZA CTR'),
        aip(id: 'anac_ctr_saez', name: 'CTR EZEIZA', lowerAgl: 0),
      ]);

      final zone = result.single;
      // OpenAIP geometry...
      expect(zone.id, 'openaip_eze');
      expect(zone.polygon, isNotNull);
      expect(zone.source, ZoneSourceIds.openaip);
      // ...with AIP authority.
      expect(zone.confirmedBy, ZoneSourceIds.aip);
      expect(zone.categoryId, 'restricted');
      expect(zone.allowedPermissionIds, {'special_permit'});
      expect(zone.lowerLimitMetersAgl, 0);
    });

    test('collapses each distinct pair independently (EZE + Aeroparque)', () {
      final result = ZoneMerger.merge([
        openAip(id: 'openaip_eze', name: 'EZEIZA CTR'),
        openAip(id: 'openaip_aep', name: 'AEROPARQUE JORGE NEWBERY CTR'),
        aip(id: 'anac_ctr_saez', name: 'CTR EZEIZA'),
        aip(id: 'anac_ctr_sabe', name: 'AEROPARQUE CTR'),
      ]);

      expect(result, hasLength(2));
      expect(
        result.every((z) => z.confirmedBy == ZoneSourceIds.aip),
        isTrue,
      );
      expect(
        result.map((z) => z.id),
        containsAll(['openaip_eze', 'openaip_aep']),
      );
    });

    test('prefers the OpenAIP zone that carries a real polygon', () {
      final result = ZoneMerger.merge([
        // Same matchKey, but only the second OpenAIP has geometry.
        openAip(
          id: 'openaip_eze_circle',
          name: 'EZEIZA CTR',
          polygon: const [],
        ),
        openAip(id: 'openaip_eze_poly', name: 'EZEIZA CTR'),
        aip(id: 'anac_ctr_saez', name: 'CTR EZEIZA'),
      ]);

      // The circle OpenAIP zone is left untouched; the polygon one merges.
      final mergedIds = result.map((z) => z.id).toList();
      expect(mergedIds, contains('openaip_eze_poly'));
      expect(
        result.firstWhere((z) => z.id == 'openaip_eze_poly').confirmedBy,
        ZoneSourceIds.aip,
      );
    });

    test('keeps both zones when only one source is present (matchKey miss)',
        () {
      final input = [
        openAip(id: 'openaip_sar01', name: 'SAR 01 Capital Federal'),
        openAip(id: 'openaip_sar02', name: 'SAR 02 Campo de Mayo'),
      ];
      expect(ZoneMerger.merge(input), input);
    });

    test('leaves keyless zones (no matchKey) untouched', () {
      final input = [
        aip(id: 'anac_x', name: 'Parque Nacional Iguazú'),
        openAip(id: 'openaip_y', name: 'Some Local Field'),
      ];
      expect(ZoneMerger.merge(input), input);
    });

    test('SAR designators pair across sources by number', () {
      final result = ZoneMerger.merge([
        openAip(
          id: 'openaip_sar07',
          name: 'SAR 07 Zarate',
          categoryId: 'restricted',
        ),
        aip(id: 'anac_sar_07', name: 'SAR 07 Central Atucha'),
      ]);

      expect(result, hasLength(1));
      expect(result.single.id, 'openaip_sar07');
      expect(result.single.confirmedBy, ZoneSourceIds.aip);
    });
  });
}
