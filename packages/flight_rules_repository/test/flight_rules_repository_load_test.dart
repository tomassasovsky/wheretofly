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

    test('returns backend feed zones when available', () async {
      final repo = await FlightRulesRepository.load(
        feed: _StubFeed([liveOnly]),
        offlineFallback: _StubBundled([bundledOnly]),
      );

      final ids = repo.zones.map((z) => z.id).toSet();
      expect(ids, {'live_only'});
    });

    test('falls back to bundled snapshot when feed is empty', () async {
      final repo = await FlightRulesRepository.load(
        feed: _StubFeed(const []),
        offlineFallback: _StubBundled([bundledOnly]),
      );

      final ids = repo.zones.map((z) => z.id).toSet();
      expect(ids, {'bundled_only'});
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
