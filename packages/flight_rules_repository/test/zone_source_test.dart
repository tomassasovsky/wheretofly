import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:test/test.dart';
import 'package:zones_api_client/zones_api_client.dart';

void main() {
  group('ZoneSource.fromId', () {
    test('resolves each canonical data-layer source id', () {
      expect(ZoneSource.fromId(ZoneSourceIds.aip), ZoneSource.aip);
      expect(ZoneSource.fromId(ZoneSourceIds.openaip), ZoneSource.openaip);
      expect(ZoneSource.fromId(ZoneSourceIds.notam), ZoneSource.notam);
      expect(ZoneSource.fromId(ZoneSourceIds.madhel), ZoneSource.madhel);
      expect(ZoneSource.fromId(ZoneSourceIds.bundled), ZoneSource.bundled);
    });

    test('defaults to bundled for unknown or missing ids', () {
      expect(ZoneSource.fromId(null), ZoneSource.bundled);
      expect(ZoneSource.fromId('whatever'), ZoneSource.bundled);
    });

    test('enum ids round-trip through fromId', () {
      for (final source in ZoneSource.values) {
        expect(ZoneSource.fromId(source.id), source);
      }
    });
  });
}
