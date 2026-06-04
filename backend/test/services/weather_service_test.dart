import 'package:backend/services/weather_service.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  group('WeatherService', () {
    late _MockHttpClient httpClient;

    setUp(() {
      httpClient = _MockHttpClient();
      registerFallbackValue(Uri.parse('http://localhost'));
    });

    test('returns good advisory for calm Open-Meteo conditions', () async {
      when(() => httpClient.get(any())).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments.first as Uri;
        if (uri.host == 'api.open-meteo.com') {
          return http.Response(_calmOpenMeteoJson, 200);
        }
        return http.Response(_emptyRss, 200);
      });

      final service = WeatherService(httpClient: httpClient);
      final snapshot = await service.getWeather(lat: -34.6, lon: -58.4);

      expect(snapshot.advisory['level'], 'good');
      expect(snapshot.current['wind_speed'], 3.0);
      expect(snapshot.hourly, isNotEmpty);
    });

    test('returns not recommended when SMN alerts are present', () async {
      when(() => httpClient.get(any())).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments.first as Uri;
        if (uri.host == 'api.open-meteo.com') {
          return http.Response(_calmOpenMeteoJson, 200);
        }
        return http.Response(_smnAlertRss, 200);
      });

      final service = WeatherService(httpClient: httpClient);
      final snapshot = await service.getWeather(lat: -34.6, lon: -58.4);

      expect(snapshot.advisory['level'], 'notRecommended');
      expect(snapshot.alerts, isNotEmpty);
    });
  });
}

const _calmOpenMeteoJson = '''
{
  "current": {
    "wind_speed_10m": 3.0,
    "wind_gusts_10m": 4.0,
    "wind_direction_10m": 180,
    "relative_humidity_2m": 50
  },
  "hourly": {
    "time": ["2024-06-01T12:00", "2024-06-01T13:00"],
    "wind_speed_10m": [3.0, 3.5],
    "wind_gusts_10m": [4.0, 4.5],
    "wind_direction_10m": [180, 190]
  }
}
''';

const _emptyRss = '''
<?xml version="1.0"?>
<rss version="2.0"><channel></channel></rss>
''';

const _smnAlertRss = '''
<?xml version="1.0"?>
<rss version="2.0">
  <channel>
    <item>
      <title>Tormenta</title>
      <description>Alerta activa</description>
    </item>
  </channel>
</rss>
''';
