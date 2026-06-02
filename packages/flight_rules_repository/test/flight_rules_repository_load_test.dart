import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:test/test.dart';
import 'package:zones_api_client/zones_api_client.dart';

void main() {
  group('FlightRulesRepository.load', () {
    const bundledOnly = ZoneData(
      id: 'bundled_only',
      name: 'Bundled',
      categoryId: 'prohibited',
      latitude: -34.6,
      longitude: -58.4,
      radiusMeters: 1000,
      allowedPermissionIds: {},
      details: 'bundled',
    );

    const liveOnly = ZoneData(
      id: 'live_only',
      name: 'Live',
      categoryId: 'restricted',
      latitude: -34.5,
      longitude: -58.5,
      radiusMeters: 2000,
      allowedPermissionIds: {'special_permit'},
      details: 'live',
    );

    test('keeps bundled zones when live feeds return data', () async {
      final repo = await FlightRulesRepository.load(
        geojson: _StubFeed([liveOnly]),
        bundled: _StubBundled([bundledOnly]),
      );

      final ids = repo.zones.map((z) => z.id).toSet();
      expect(ids, containsAll(['bundled_only', 'live_only']));
    });

    test('live feed overrides bundled zone with same id', () async {
      const override = ZoneData(
        id: 'bundled_only',
        name: 'Overridden',
        categoryId: 'restricted',
        latitude: -34.6,
        longitude: -58.4,
        radiusMeters: 500,
        allowedPermissionIds: {'special_permit'},
        details: 'live override',
      );

      final repo = await FlightRulesRepository.load(
        geojson: _StubFeed([override]),
        bundled: _StubBundled([bundledOnly]),
      );

      final zone = repo.zones.singleWhere((z) => z.id == 'bundled_only');
      expect(zone.name, 'Overridden');
    });

    test('live MADHEL feed overrides bundled aerodrome with same id', () async {
      const bundledAerodrome = ZoneData(
        id: 'madhel_AER',
        name: 'Old Aeroparque',
        categoryId: 'controlled_airspace',
        latitude: -34.55,
        longitude: -58.41,
        radiusMeters: 9000,
        allowedPermissionIds: {'special_permit'},
        details: 'bundled',
      );
      const liveAerodrome = ZoneData(
        id: 'madhel_AER',
        name: 'Updated Aeroparque',
        categoryId: 'controlled_airspace',
        latitude: -34.559,
        longitude: -58.416,
        radiusMeters: 12000,
        allowedPermissionIds: {'special_permit'},
        details: 'live',
      );

      final repo = await FlightRulesRepository.load(
        madhel: _StubMadhel([liveAerodrome]),
        bundled: _StubBundled([bundledAerodrome, bundledOnly]),
      );

      final aerodrome = repo.zones.singleWhere((z) => z.id == 'madhel_AER');
      expect(aerodrome.name, 'Updated Aeroparque');
      expect(repo.zones.map((z) => z.id), contains('bundled_only'));
    });
  });
}

class _StubBundled extends BundledZonesApiClient {
  _StubBundled(this._zones);

  final List<ZoneData> _zones;

  @override
  Future<List<ZoneData>> fetchZones() async => _zones;
}

class _StubFeed implements ZonesFeedClient {
  _StubFeed(this._zones);

  final List<ZoneData> _zones;

  @override
  Future<List<ZoneData>> fetchZones() async => _zones;
}

class _StubMadhel extends MadhelZonesApiClient {
  _StubMadhel(this._zones);

  final List<ZoneData> _zones;

  @override
  Future<List<ZoneData>> fetchZones() async => _zones;
}
