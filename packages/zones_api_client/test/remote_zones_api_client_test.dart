import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zones_api_client/zones_api_client.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late http.Client httpClient;

  setUpAll(() => registerFallbackValue(Uri.parse('http://localhost')));

  setUp(() => httpClient = _MockHttpClient());

  void stub(String body) {
    when(() => httpClient.get(any())).thenAnswer(
      (_) async => http.Response(body, 200),
    );
  }

  String feed(Map<String, Object?> properties) => jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': properties,
            'geometry': {
              'type': 'Point',
              'coordinates': [-58.4, -34.6],
            },
          },
        ],
      });

  RemoteZonesApiClient client() => RemoteZonesApiClient(
        url: Uri.parse('http://localhost/zones.geojson'),
        httpClient: httpClient,
      );

  test('parses explicit source, confirmedBy, and validity window', () async {
    stub(
      feed({
        'id': 'notam_z1',
        'name': 'Temporary',
        'categoryId': 'restricted',
        'radiusMeters': 1000,
        'allowedPermissionIds': <String>[],
        'details': 'x',
        'source': 'openaip',
        'confirmedBy': 'aip',
        'activeFrom': '2026-06-18T15:00:00-03:00',
        'activeTo': '2026-06-18T21:00:00-03:00',
      }),
    );

    final zone = (await client().fetchZones()).single;
    expect(zone.source, ZoneSourceIds.openaip);
    expect(zone.confirmedBy, ZoneSourceIds.aip);
    expect(zone.activeFrom, DateTime.utc(2026, 6, 18, 18));
    expect(zone.activeTo, DateTime.utc(2026, 6, 19));
  });

  test('falls back to the id prefix when source is absent', () async {
    stub(
      feed({
        'id': 'madhel_legacy',
        'name': 'Legacy',
        'categoryId': 'restricted',
        'radiusMeters': 1000,
        'allowedPermissionIds': <String>[],
        'details': 'x',
      }),
    );

    final zone = (await client().fetchZones()).single;
    expect(zone.source, ZoneSourceIds.madhel);
    expect(zone.confirmedBy, isNull);
    expect(zone.activeFrom, isNull);
    expect(zone.activeTo, isNull);
  });

  test('repairs mojibaked UTF-8 names from the feed', () async {
    final mojibake = latin1.decode(utf8.encode('Lanús'));
    stub(
      feed({
        'id': 'openaip_x',
        'name': mojibake,
        'categoryId': 'restricted',
        'radiusMeters': 1000,
        'allowedPermissionIds': <String>[],
        'details': 'x',
      }),
    );

    expect((await client().fetchZones()).single.name, 'Lanús');
  });
}
