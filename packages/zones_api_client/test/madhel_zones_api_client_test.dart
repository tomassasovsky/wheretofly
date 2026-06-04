import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:zones_api_client/src/madhel_zones_api_client.dart';

void main() {
  group('MadhelZonesApiClient', () {
    test('parses aerodrome list from MADHEL API shape', () async {
      final client = MadhelZonesApiClient(
        httpClient: _MockHttpClient(
          jsonEncode({
            'count': 1,
            'results': [
              {
                'local_identifier': 'EZE',
                'human_readable_identifier':
                    'EZEIZA / MINISTRO PISTARINI - (EZE / SAEZ) - DRCE - '
                        'PÚBLICO CONTROLADO INTERNACIONAL',
                'the_geom': {
                  'geometry': {
                    'coordinates': [-58.5358, -34.8222],
                  },
                },
              },
            ],
          }),
        ),
      );

      final zones = await client.fetchZones();
      expect(zones, hasLength(1));
      expect(zones.first.id, 'madhel_EZE');
      expect(zones.first.radiusMeters, 9000);
    });

    test('throws when response is empty', () async {
      final client = MadhelZonesApiClient(
        httpClient:
            _MockHttpClient(jsonEncode({'count': 0, 'results': <dynamic>[]})),
      );

      expect(client.fetchZones(), throwsA(isA<MadhelException>()));
    });
  });
}

class _MockHttpClient extends http.BaseClient {
  _MockHttpClient(this._body);

  final String _body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(_body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
