import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_repository/location_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:where_to_fly/map/cubit/map_search_cubit.dart';

class _MockGeocodingRepository extends Mock implements GeocodingRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late _MockGeocodingRepository geocoding;
  late _MockLocationRepository location;

  setUp(() {
    geocoding = _MockGeocodingRepository();
    location = _MockLocationRepository();
  });

  MapSearchCubit buildCubit() => MapSearchCubit(
        geocodingRepository: geocoding,
        locationRepository: location,
      );

  blocTest<MapSearchCubit, MapSearchState>(
    'selectResult emits focus point and compact label',
    build: buildCubit,
    act: (cubit) => cubit.selectResult(
      const GeocodeResult(
        label: 'Plaza de Mayo, Buenos Aires, Argentina',
        point: LatLng(-34.608, -58.37),
      ),
    ),
    expect: () => [
      isA<MapSearchState>()
          .having((s) => s.focusPoint?.latitude, 'lat', -34.608)
          .having(
            (s) => s.resolvedAddressLabel,
            'label',
            'Plaza de Mayo, Buenos Aires',
          ),
    ],
  );

  blocTest<MapSearchCubit, MapSearchState>(
    'clearSearch resets to initial state',
    build: buildCubit,
    seed: () => const MapSearchState(
      showResults: true,
      searching: true,
      activeQuery: 'test',
    ),
    act: (cubit) => cubit.clearSearch(),
    expect: () => [const MapSearchState()],
  );

  blocTest<MapSearchCubit, MapSearchState>(
    'selectResult outside Argentina sets warning flag',
    build: buildCubit,
    act: (cubit) => cubit.selectResult(
      const GeocodeResult(
        label: 'Santiago, Chile',
        point: LatLng(-33.45, -70.66),
      ),
    ),
    expect: () => [
      isA<MapSearchState>()
          .having((s) => s.focusPoint?.latitude, 'lat', -33.45)
          .having((s) => s.outsideArgentina, 'outside', isTrue),
    ],
  );

  blocTest<MapSearchCubit, MapSearchState>(
    'locateMe emits focus point when inside Argentina',
    build: buildCubit,
    setUp: () {
      when(() => location.currentLocation()).thenAnswer(
        (_) async => const LatLng(-34.6, -58.4),
      );
    },
    act: (cubit) => cubit.locateMe(),
    expect: () => [
      isA<MapSearchState>().having((s) => s.locating, 'locating', isTrue),
      isA<MapSearchState>()
          .having((s) => s.locating, 'locating', isFalse)
          .having((s) => s.focusPoint?.latitude, 'lat', -34.6)
          .having((s) => s.outsideArgentina, 'outside', isFalse),
    ],
  );

  blocTest<MapSearchCubit, MapSearchState>(
    'locateMe outside Argentina still focuses with warning flag',
    build: buildCubit,
    setUp: () {
      when(() => location.currentLocation()).thenAnswer(
        (_) async => const LatLng(-33.45, -70.66),
      );
    },
    act: (cubit) => cubit.locateMe(),
    expect: () => [
      isA<MapSearchState>().having((s) => s.locating, 'locating', isTrue),
      isA<MapSearchState>()
          .having((s) => s.locating, 'locating', isFalse)
          .having((s) => s.focusPoint?.latitude, 'lat', -33.45)
          .having((s) => s.outsideArgentina, 'outside', isTrue),
    ],
  );
}
