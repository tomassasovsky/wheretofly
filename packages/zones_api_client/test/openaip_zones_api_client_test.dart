import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:zones_api_client/src/openaip_zones_api_client.dart';
import 'package:zones_api_client/src/zone_permission_ids.dart';

void main() {
  group('OpenAipZonesApiClient', () {
    test('parses polygon airspace with category and altitude limits', () async {
      final client = OpenAipZonesApiClient(
        apiKey: 'test-key',
        httpClient: _MockHttpClient(
          jsonEncode({
            'items': [
              {
                '_id': 'abc123',
                'name': 'EZE CTR',
                'type': 4,
                'geometry': {
                  'type': 'Polygon',
                  'coordinates': [
                    [
                      [-58.55, -34.82],
                      [-58.45, -34.82],
                      [-58.45, -34.78],
                      [-58.55, -34.78],
                      [-58.55, -34.82],
                    ],
                  ],
                },
                'lowerCeiling': {
                  'value': 0,
                  'unit': 'FT',
                  'referenceDatum': 'GND',
                },
                'upperCeiling': {
                  'value': 2500,
                  'unit': 'FT',
                  'referenceDatum': 'MSL',
                },
              },
            ],
          }),
        ),
      );

      final zones = await client.fetchZones();
      expect(zones, hasLength(1));
      expect(zones.first.id, 'openaip_abc123');
      expect(zones.first.name, 'EZE CTR');
      expect(zones.first.categoryId, 'controlled_airspace');
      expect(zones.first.lowerLimitMetersAgl, 0);
      expect(zones.first.upperLimitMetersMsl, isNotNull);
      expect(zones.first.radiusMeters, greaterThanOrEqualTo(500));
      // The true boundary ring is preserved (not flattened to a circle).
      expect(zones.first.polygon, isNotNull);
      expect(zones.first.polygon!.first, [-58.5, -34.5]);
      expect(zones.first.polygon, hasLength(5));
    });

    test('maps SAR as restricted area with commercial permissions', () async {
      final client = OpenAipZonesApiClient(
        apiKey: 'test-key',
        httpClient: _MockHttpClient(
          jsonEncode({
            'items': [
              {
                '_id': 'sar01',
                'name': 'SAR 01 Capital Federal',
                'type': 9,
                'geometry': _polygon,
              },
            ],
          }),
        ),
      );

      final zones = await client.fetchZones();
      expect(zones, hasLength(1));
      expect(zones.first.categoryId, 'restricted');
      expect(
        zones.first.allowedPermissionIds,
        ZonePermissionIds.controlledAirspace,
      );
    });

    test('skips excluded FIR types', () async {
      final client = OpenAipZonesApiClient(
        apiKey: 'test-key',
        httpClient: _MockHttpClient(
          jsonEncode({
            'items': [
              {'_id': 'fir', 'name': 'FIR', 'type': 10, 'geometry': _polygon},
            ],
          }),
        ),
      );

      expect(await client.fetchZones(), isEmpty);
    });
  });
}

const _polygon = {
  'type': 'Polygon',
  'coordinates': [
    [
      [-58.5, -34.5],
      [-58.4, -34.5],
      [-58.4, -34.4],
      [-58.5, -34.4],
      [-58.5, -34.5],
    ],
  ],
};

class _MockHttpClient extends http.BaseClient {
  _MockHttpClient(this._body);

  final String _body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(_body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
