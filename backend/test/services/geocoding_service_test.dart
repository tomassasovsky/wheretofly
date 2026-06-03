import 'package:backend/config/app_config.dart';
import 'package:backend/services/geocoding_service.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  group('GeocodingService', () {
    late _MockHttpClient httpClient;

    setUp(() {
      httpClient = _MockHttpClient();
      registerFallbackValue(Uri.parse('http://localhost'));
    });

    test('search calls self-hosted Photon base URL', () async {
      when(() => httpClient.get(any())).thenAnswer(
        (_) async => http.Response(_buenosFeatureCollection, 200),
      );

      final service = GeocodingService(
        config: _testConfig(photonBaseUrl: 'http://photon:2322'),
        httpClient: httpClient,
      );

      final results = await service.search('Buenos Aires');
      expect(results, hasLength(1));
      expect(results.first.label, contains('Buenos Aires'));
      expect(results.first.latitude, closeTo(-34.6, 0.1));

      final captured =
          verify(() => httpClient.get(captureAny())).captured.single as Uri;
      expect(captured.host, 'photon');
      expect(captured.port, 2322);
      expect(captured.path, '/api/');
      expect(captured.queryParameters['q'], 'Buenos Aires');
    });

    test('reverse geocodes via Photon', () async {
      when(() => httpClient.get(any())).thenAnswer(
        (_) async => http.Response(_buenosFeatureCollection, 200),
      );

      final service = GeocodingService(
        config: _testConfig(),
        httpClient: httpClient,
      );

      final hit = await service.reverse(lat: -34.6, lon: -58.4);
      expect(hit.label, isNotEmpty);

      final captured =
          verify(() => httpClient.get(captureAny())).captured.single as Uri;
      expect(captured.path, '/reverse');
    });
  });
}

AppConfig _testConfig({String photonBaseUrl = 'http://localhost:2322'}) {
  return AppConfig(
    databaseUrl: '',
    redisUrl: '',
    jwtSecret: '',
    openAipApiKey: '',
    photonBaseUrl: photonBaseUrl,
    minioEndpoint: '',
    minioAccessKey: '',
    minioSecretKey: '',
    minioBucket: '',
    googleClientId: '',
    appleClientId: '',
    zoneFeedPath: '',
  );
}

const _buenosFeatureCollection = '''
{
  "features": [
    {
      "type": "Feature",
      "geometry": {"type": "Point", "coordinates": [-58.4, -34.6]},
      "properties": {
        "name": "Buenos Aires",
        "city": "Buenos Aires",
        "countrycode": "AR"
      }
    }
  ]
}
''';
