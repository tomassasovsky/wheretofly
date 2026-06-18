import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:zones_api_client/src/openaip_export_zones_api_client.dart';

void main() {
  group('OpenAipExportZonesApiClient', () {
    test('parses ND-GeoJSON export features with polygon boundaries', () async {
      final client = OpenAipExportZonesApiClient(
        httpClient: _MockHttpClient(
          '''
{"type":"Feature","properties":{"_id":"abc123","name":"EZE CTR","type":4,"lowerLimit":{"value":0,"unit":1,"referenceDatum":0},"upperLimit":{"value":2500,"unit":1,"referenceDatum":1}},"geometry":{"type":"Polygon","coordinates":[[[-58.55,-34.82],[-58.45,-34.82],[-58.45,-34.78],[-58.55,-34.78],[-58.55,-34.82]]]}}
''',
        ),
      );

      final zones = await client.fetchZones();
      expect(zones, hasLength(1));
      expect(zones.first.id, 'openaip_abc123');
      expect(zones.first.categoryId, 'controlled_airspace');
      expect(zones.first.polygon, isNotNull);
      expect(zones.first.lowerLimitMetersAgl, 0);
      expect(zones.first.upperLimitMetersMsl, isNotNull);
    });

    test('skips excluded FIR types from export', () async {
      final client = OpenAipExportZonesApiClient(
        httpClient: _MockHttpClient(
          '''
{"type":"Feature","properties":{"_id":"fir","name":"FIR","type":10},"geometry":{"type":"Polygon","coordinates":[[[-58.5,-34.5],[-58.4,-34.5],[-58.4,-34.4],[-58.5,-34.4],[-58.5,-34.5]]]}}
''',
        ),
      );

      expect(
        () => client.fetchZones(),
        throwsA(isA<OpenAipExportException>()),
      );
    });
  });
}

class _MockHttpClient extends http.BaseClient {
  _MockHttpClient(this._body);

  final String _body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(_body)),
      200,
      headers: {'content-type': 'application/geo+json-seq'},
    );
  }
}
