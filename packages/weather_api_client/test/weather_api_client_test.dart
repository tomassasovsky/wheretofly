import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:weather_api_client/weather_api_client.dart';

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
  group('WeatherApiClient', () {
    final baseUrl = Uri.parse('http://localhost:8080');

    WeatherApiClient buildClient(
      _FakeHttpClient fake, {
      String? token = 'token',
    }) {
      return WeatherApiClient(
        baseUrl: baseUrl,
        accessTokenProvider: () async => token,
        httpClient: fake,
      );
    }

    test('fetch parses a weather snapshot', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'fetchedAt': '2024-01-01T00:00:00Z',
          'location': {'lat': -34.6, 'lon': -58.4},
          'current': {'wind_speed': 5.0},
          'advisory': {
            'level': 'good',
            'reasons': ['calm'],
          },
        }),
      );

      final snapshot = await buildClient(fake).fetch(lat: -34.6, lon: -58.4);

      expect(snapshot.advisoryLevel, WeatherAdvisoryLevel.good);
      expect(snapshot.advisoryReasons, ['calm']);
      expect(snapshot.windSpeedMs, 5.0);
      expect(fake.lastRequest!.url.path, '/v1/weather');
    });

    test('fetch throws on a non-200 response', () async {
      final fake = _FakeHttpClient(statusCode: 502);

      await expectLater(
        buildClient(fake).fetch(lat: 0, lon: 0),
        throwsA(
          isA<WeatherApiException>()
              .having((e) => e.statusCode, 'statusCode', 502),
        ),
      );
    });

    test('listAlertSubscriptions throws 401 when unauthenticated', () async {
      final fake = _FakeHttpClient();

      await expectLater(
        buildClient(fake, token: null).listAlertSubscriptions(),
        throwsA(
          isA<WeatherApiException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('listAlertSubscriptions parses the subscriptions array', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'subscriptions': [
            {
              'id': 's1',
              'label': 'Home',
              'lat': -34.6,
              'lon': -58.4,
              'windThresholdMs': 10,
            },
          ],
        }),
      );

      final items = await buildClient(fake).listAlertSubscriptions();

      expect(items, hasLength(1));
      expect(items.first.id, 's1');
      expect(items.first.windThresholdMs, 10);
    });

    test('createAlertSubscription parses the created subscription', () async {
      final fake = _FakeHttpClient(
        body: jsonEncode({
          'id': 's2',
          'label': 'Field',
          'lat': -31.4,
          'lon': -64.2,
          'windThresholdMs': 8,
        }),
      );

      final created = await buildClient(fake).createAlertSubscription(
        label: 'Field',
        lat: -31.4,
        lon: -64.2,
      );

      expect(created.id, 's2');
      expect(created.label, 'Field');
    });

    test('deleteAlertSubscription throws on failure', () async {
      final fake = _FakeHttpClient(statusCode: 500);

      await expectLater(
        buildClient(fake).deleteAlertSubscription('s1'),
        throwsA(isA<WeatherApiException>()),
      );
    });
  });
}
