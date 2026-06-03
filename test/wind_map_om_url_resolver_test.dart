import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:where_to_fly/map/wind_map_om_url_resolver.dart';

void main() {
  group('WindMapOmUrlResolver', () {
    test('returns latest.json URL when metadata is valid', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/data_spatial/dwd_icon/latest.json');
        expect(request.url.queryParameters['variable'], 'wind_gusts_10m');
        return http.Response(
          '''
{
  "reference_time": "2026-06-03T00:00:00Z",
  "variables": ["wind_gusts_10m", "wind_u_component_10m"],
  "valid_times": ["2026-06-03T00:00Z"]
}
''',
          200,
        );
      });

      final url = await WindMapOmUrlResolver(client: client).resolve();

      expect(
        url,
        'https://map-tiles.open-meteo.com/data_spatial/dwd_icon/'
        'latest.json?time_step=current_time_1H&variable=wind_gusts_10m',
      );
    });

    test('throws on non-200 metadata', () async {
      final client = MockClient((_) async => http.Response('', 503));
      expect(
        () => WindMapOmUrlResolver(client: client).resolve(),
        throwsA(isA<WindMapResolveException>()),
      );
    });
  });
}
