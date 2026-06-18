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

  test('parses explicit source, confirmedBy, and validity window', () async {
    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
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
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [-58.4, -34.6],
          },
        },
      ],
    });

    when(
      () => httpClient.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response(geojson, 200));

    final client = BackendZonesApiClient(
      baseUrl: Uri.parse('http://localhost:8080'),
      storage: storage,
      httpClient: httpClient,
    );

    final zone = (await client.fetchZones()).single;
    expect(zone.source, 'openaip');
    expect(zone.confirmedBy, 'aip');
    expect(zone.activeFrom, DateTime.utc(2026, 6, 18, 18));
    expect(zone.activeTo, DateTime.utc(2026, 6, 19));
  });

  test('falls back to the id prefix when source is absent', () async {
    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'id': 'openaip_legacy',
            'name': 'Legacy',
            'categoryId': 'restricted',
            'radiusMeters': 1000,
            'allowedPermissionIds': <String>[],
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
      () => httpClient.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response(geojson, 200));

    final client = BackendZonesApiClient(
      baseUrl: Uri.parse('http://localhost:8080'),
      storage: storage,
      httpClient: httpClient,
    );

    final zone = (await client.fetchZones()).single;
    expect(zone.source, 'openaip');
    expect(zone.activeFrom, isNull);
  });

  test('parses Polygon geometry into the boundary ring', () async {
    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'id': 'ctr_1',
            'name': 'CTR',
            'categoryId': 'controlled_airspace',
            'latitude': -34.5,
            'longitude': -58.5,
            'radiusMeters': 8000,
            'allowedPermissionIds': ['controlled'],
            'details': 'x',
          },
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-59.0, -34.0],
                [-58.0, -34.0],
                [-58.0, -35.0],
                [-59.0, -35.0],
                [-59.0, -34.0],
              ],
            ],
          },
        },
      ],
    });

    when(
      () => httpClient.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response(geojson, 200));

    final client = BackendZonesApiClient(
      baseUrl: Uri.parse('http://localhost:8080'),
      storage: storage,
      httpClient: httpClient,
    );

    final zones = await client.fetchZones();
    expect(zones, hasLength(1));
    final zone = zones.first;
    // Centre comes from properties, not the geometry.
    expect(zone.latitude, -34.5);
    expect(zone.longitude, -58.5);
    // Ring preserved as [lon, lat] pairs, including the closing vertex.
    expect(zone.polygon, isNotNull);
    expect(zone.polygon!.first, [-59.0, -34.0]);
    expect(zone.polygon!.length, 5);
  });
}
