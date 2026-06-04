@Tags(['skip_very_good_optimization'])
library;

import 'dart:convert';

import 'package:backend_zones_api_client/backend_zones_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

class _MockHttpClient extends Mock implements http.Client {}

class _MockStorage extends Mock implements Storage {}

void main() {
  late http.Client httpClient;
  late Storage storage;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    httpClient = _MockHttpClient();
    storage = _MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
  });

  test('fetchZones works without auth token', () async {
    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'id': 'zone_1',
            'name': 'Test',
            'categoryId': 'restricted',
            'radiusMeters': 1000,
            'allowedPermissionIds': ['recreational'],
            'details': 'x',
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [-58.4, -34.6],
          },
        },
      ],
    });

    when(
      () => httpClient.get(
        any(),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (_) async => http.Response(geojson, 200, headers: {'etag': '"v1"'}),
    );

    final client = BackendZonesApiClient(
      baseUrl: Uri.parse('http://localhost:8080'),
      storage: storage,
      httpClient: httpClient,
    );

    final zones = await client.fetchZones();
    expect(zones, hasLength(1));
  });

  test('fetchZones stores etag and parses features', () async {
    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'id': 'zone_1',
            'name': 'Test',
            'categoryId': 'restricted',
            'radiusMeters': 1000,
            'allowedPermissionIds': ['recreational'],
            'details': 'x',
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [-58.4, -34.6],
          },
        },
      ],
    });

    when(
      () => httpClient.get(
        any(),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        geojson,
        200,
        headers: {
          'etag': '"v1"',
          'x-zone-version': 'v1',
          'x-zone-updated-at': '2026-06-02T12:00:00Z',
        },
      ),
    );

    final client = BackendZonesApiClient(
      baseUrl: Uri.parse('http://localhost:8080'),
      accessTokenProvider: () async => 'token',
      storage: storage,
      httpClient: httpClient,
    );

    final zones = await client.fetchZones();
    expect(zones, hasLength(1));
    expect(zones.first.id, 'zone_1');
    verify(() => storage.write('zone_feed_etag', '"v1"')).called(1);
  });
}
