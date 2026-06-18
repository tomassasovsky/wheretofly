import 'dart:convert';

import 'package:test/test.dart';
import 'package:zones_api_client/zones_api_client.dart';

void main() {
  const reader = AipGeoJsonReader();

  String geojson(Map<String, Object?> properties) => jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': properties,
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-58.6, -34.9],
                  [-58.4, -34.9],
                  [-58.4, -34.7],
                  [-58.6, -34.7],
                  [-58.6, -34.9],
                ],
              ],
            },
          },
        ],
      });

  test('tags every parsed zone with the AIP source', () {
    final zones = reader.parse(
      geojson({
        'id': 'anac_sar_01',
        'name': 'SAR 01',
        'categoryId': 'restricted',
        'latitude': -34.8,
        'longitude': -58.5,
        'radiusMeters': 12000,
        'allowedPermissionIds': <String>['special_permit'],
        'details': 'Zona restringida',
      }),
    );

    final zone = zones.single;
    expect(zone.source, ZoneSourceIds.aip);
    expect(zone.id, 'anac_sar_01');
    expect(zone.categoryId, 'restricted');
    expect(zone.polygon, isNotNull);
    expect(zone.polygon!.first, [-58.6, -34.9]);
  });

  test('repairs mojibaked UTF-8 in names', () {
    // UTF-8 bytes of "Lanús" misread as Latin-1 — the exact corruption the
    // reader exists to undo.
    final mojibake = latin1.decode(utf8.encode('Lanús'));
    expect(mojibake, isNot('Lanús'));

    final zones = reader.parse(
      geojson({
        'id': 'anac_sar_02',
        'name': mojibake,
        'categoryId': 'restricted',
        'latitude': -34.7,
        'longitude': -58.4,
        'radiusMeters': 8000,
        'allowedPermissionIds': <String>[],
        'details': 'x',
      }),
    );

    expect(zones.single.name, 'Lanús');
  });

  test('returns an empty list for a non-FeatureCollection body', () {
    expect(reader.parse('[]'), isEmpty);
    expect(reader.parse('{}'), isEmpty);
  });
}
