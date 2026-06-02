import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_api_client/weather_api_client.dart';
import 'package:weather_repository/weather_repository.dart';

enum MapWeatherStatus { idle, loading, loaded, error, requiresAuth }

class MapWeatherState extends Equatable {
  const MapWeatherState({
    this.status = MapWeatherStatus.idle,
    this.snapshot,
    this.errorMessage,
  });

  final MapWeatherStatus status;
  final WeatherSnapshot? snapshot;
  final String? errorMessage;

  MapWeatherState copyWith({
    MapWeatherStatus? status,
    WeatherSnapshot? snapshot,
    String? errorMessage,
    bool clearSnapshot = false,
    bool clearError = false,
  }) {
    return MapWeatherState(
      status: status ?? this.status,
      snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, snapshot, errorMessage];
}

/// Fetches weather for the selected map point when the user is authenticated.
class MapWeatherCubit extends Cubit<MapWeatherState> {
  MapWeatherCubit({
    required WeatherRepository weatherRepository,
    required Future<bool> Function() isAuthenticated,
  })  : _weatherRepository = weatherRepository,
        _isAuthenticated = isAuthenticated,
        super(const MapWeatherState());

  final WeatherRepository _weatherRepository;
  final Future<bool> Function() _isAuthenticated;

  Future<void> fetchFor(LatLng point) async {
    if (!await _isAuthenticated()) {
      emit(
        const MapWeatherState(status: MapWeatherStatus.requiresAuth),
      );
      return;
    }

    emit(
      state.copyWith(
        status: MapWeatherStatus.loading,
        clearError: true,
        clearSnapshot: true,
      ),
    );

    try {
      final snapshot = await _weatherRepository.getWeather(point);
      emit(
        MapWeatherState(
          status: MapWeatherStatus.loaded,
          snapshot: snapshot,
        ),
      );
    } on WeatherApiException catch (e) {
      if (e.statusCode == 401) {
        emit(const MapWeatherState(status: MapWeatherStatus.requiresAuth));
        return;
      }
      emit(
        MapWeatherState(
          status: MapWeatherStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        const MapWeatherState(
          status: MapWeatherStatus.error,
          errorMessage: 'weather_fetch_failed',
        ),
      );
    }
  }

  void clear() => emit(const MapWeatherState());
}
