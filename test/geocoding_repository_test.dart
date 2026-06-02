import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_api_client/geocoding_api_client.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';

class _MockGeocodingApiClient extends Mock implements GeocodingApiClient {}

void main() {
  group('GeocodingRepository', () {
    late _MockGeocodingApiClient apiClient;
    late Storage storage;

    setUp(() async {
      apiClient = _MockGeocodingApiClient();
      SharedPreferences.setMockInitialValues({});
      storage = Storage(await SharedPreferences.getInstance());
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

      final repository = GeocodingRepository(
        apiClient: apiClient,
        storage: storage,
      );

      await storage.write(
        'geocode_buenos aires',
        '${cached.point.latitude}|${cached.point.longitude}|${cached.label}',
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

      final repository = GeocodingRepository(
        apiClient: apiClient,
        storage: storage,
      );

      await storage.write(
        'geocode_rev_-34.6000_-58.4000',
        '${point.latitude}|${point.longitude}|${cached.label}',
      );

      final result = await repository.reverse(point);
      expect(result.label, cached.label);
    });
  });
}
