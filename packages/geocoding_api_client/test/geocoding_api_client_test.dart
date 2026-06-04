import 'dart:convert';

import 'package:geocoding_api_client/geocoding_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({this.statusCode = 200, this.body = '{}'});

  int statusCode;
  String body;
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('GeocodingApiClient', () {
    final baseUrl = Uri.parse('http://localhost:8080');

    test('search parses results', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'results': [
            {'label': 'Buenos Aires', 'latitude': -34.6, 'longitude': -58.4},
          ],
        }),
      );
      final client = GeocodingApiClient(baseUrl: baseUrl, httpClient: fake);

      final results = await client.search('Buenos Aires');

      expect(results, hasLength(1));
      expect(results.first.label, 'Buenos Aires');
      expect(results.first.point, const LatLng(-34.6, -58.4));
      expect(fake.lastRequest!.url.path, '/v1/geocoding/search');
    });

    test('search throws noResults on 404', () async {
      final fake = _FakeHttpClient(statusCode: 404);
      final client = GeocodingApiClient(baseUrl: baseUrl, httpClient: fake);

      await expectLater(
        client.search('nowhere'),
        throwsA(
          isA<GeocodingException>()
              .having((e) => e.reason, 'reason', GeocodingFailure.noResults),
        ),
      );
    });

    test('search throws network on a 5xx response', () async {
      final fake = _FakeHttpClient(statusCode: 500);
      final client = GeocodingApiClient(baseUrl: baseUrl, httpClient: fake);

      await expectLater(
        client.search('x'),
        throwsA(
          isA<GeocodingException>()
              .having((e) => e.reason, 'reason', GeocodingFailure.network),
        ),
      );
    });

    test('search throws noResults when the results list is empty', () async {
      final fake = _FakeHttpClient(body: jsonEncode({'results': <dynamic>[]}));
      final client = GeocodingApiClient(baseUrl: baseUrl, httpClient: fake);

      await expectLater(
        client.search('x'),
        throwsA(
          isA<GeocodingException>()
              .having((e) => e.reason, 'reason', GeocodingFailure.noResults),
        ),
      );
    });

    test('reverse parses a single hit', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'label': 'Some Street',
          'latitude': -34.6,
          'longitude': -58.4,
        }),
      );
      final client = GeocodingApiClient(baseUrl: baseUrl, httpClient: fake);

      final result = await client.reverse(const LatLng(-34.6, -58.4));

      expect(result.label, 'Some Street');
      expect(fake.lastRequest!.url.path, '/v1/geocoding/reverse');
    });

    test('reverse throws noResults on 404', () async {
      final fake = _FakeHttpClient(statusCode: 404);
      final client = GeocodingApiClient(baseUrl: baseUrl, httpClient: fake);

      await expectLater(
        client.reverse(const LatLng(0, 0)),
        throwsA(
          isA<GeocodingException>()
              .having((e) => e.reason, 'reason', GeocodingFailure.noResults),
        ),
      );
    });
  });
}
