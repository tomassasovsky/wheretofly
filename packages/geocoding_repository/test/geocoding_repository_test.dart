import 'package:geocoding_api_client/geocoding_api_client.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

class _MockGeocodingApiClient extends Mock implements GeocodingApiClient {}

class _MockStorage extends Mock implements Storage {}

void main() {
  group('GeocodingRepository', () {
    late _MockGeocodingApiClient apiClient;
    late _MockStorage storage;

    setUp(() {
      apiClient = _MockGeocodingApiClient();
      storage = _MockStorage();
      when(() => storage.write(any(), any())).thenAnswer((_) async {});
    });

    test('search returns cached result on network failure', () async {
      const query = 'Buenos Aires';
      const cached = GeocodeResult(
        label: 'Cached',
        point: LatLng(-34.6, -58.4),
      );

      when(() => apiClient.search(query)).thenThrow(
        const GeocodingException(GeocodingFailure.network),
      );
      when(() => storage.read('geocode_buenos aires')).thenReturn(
        '${cached.point.latitude}|${cached.point.longitude}|${cached.label}',
      );

      final repository = GeocodingRepository(
        apiClient: apiClient,
        storage: storage,
      );

      final results = await repository.search(query);
      expect(results, [cached]);
    });

    test('reverse returns cached result on network failure', () async {
      const point = LatLng(-34.6, -58.4);
      const cached = GeocodeResult(label: 'Cached address', point: point);

      when(() => apiClient.reverse(point)).thenThrow(
        const GeocodingException(GeocodingFailure.network),
      );
      when(() => storage.read('geocode_rev_-34.6000_-58.4000')).thenReturn(
        '${point.latitude}|${point.longitude}|${cached.label}',
      );

      final repository = GeocodingRepository(
        apiClient: apiClient,
        storage: storage,
      );

      final result = await repository.reverse(point);
      expect(result.label, cached.label);
    });
  });
}
