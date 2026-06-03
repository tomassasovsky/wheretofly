import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_api_client/weather_api_client.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/map/cubit/map_weather_cubit.dart';

class _MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  late WeatherRepository repository;

  setUp(() {
    repository = _MockWeatherRepository();
  });

  blocTest<MapWeatherCubit, MapWeatherState>(
    'loads weather snapshot for guests',
    build: () {
      when(() => repository.getWeather(any())).thenAnswer(
        (_) async => WeatherSnapshot.fromJson({
          'location': {'lat': -34.6, 'lon': -58.4},
          'fetchedAt': DateTime.now().toUtc().toIso8601String(),
          'current': {'wind_speed': 3.0, 'wind_gust': 4.0},
          'hourly': <Map<String, dynamic>>[],
          'alerts': <Map<String, dynamic>>[],
          'advisory': {
            'level': 'good',
            'reasons': ['ok'],
          },
        }),
      );
      return MapWeatherCubit(weatherRepository: repository);
    },
    act: (cubit) => cubit.fetchFor(const LatLng(-34.6, -58.4)),
    expect: () => [
      isA<MapWeatherState>().having(
        (s) => s.status,
        'status',
        MapWeatherStatus.loading,
      ),
      isA<MapWeatherState>().having(
        (s) => s.status,
        'status',
        MapWeatherStatus.loaded,
      ),
    ],
  );
}
