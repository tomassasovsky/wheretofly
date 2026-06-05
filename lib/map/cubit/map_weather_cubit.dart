import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_repository/weather_repository.dart';

enum MapWeatherStatus { idle, loading, loaded, error }

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

/// Fetches weather for the selected map point via the backend proxy.
class MapWeatherCubit extends Cubit<MapWeatherState> {
  MapWeatherCubit({required WeatherRepository weatherRepository})
      : _weatherRepository = weatherRepository,
        super(const MapWeatherState());

  final WeatherRepository _weatherRepository;
  Timer? _debounce;
  int _requestGeneration = 0;

  /// Debounces rapid map taps so Open-Meteo is not hammered on every move.
  Future<void> fetchFor(LatLng point) async {
    _debounce?.cancel();
    final generation = ++_requestGeneration;
    emit(
      state.copyWith(
        status: MapWeatherStatus.loading,
        clearError: true,
        clearSnapshot: true,
      ),
    );

    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_fetchFor(point, generation));
    });
  }

  Future<void> _fetchFor(LatLng point, int generation) async {
    if (generation != _requestGeneration) return;

    try {
      final snapshot = await _weatherRepository.getWeather(point);
      if (generation != _requestGeneration) return;
      emit(
        MapWeatherState(
          status: MapWeatherStatus.loaded,
          snapshot: snapshot,
        ),
      );
    } on WeatherApiException catch (e) {
      if (generation != _requestGeneration) return;
      emit(
        MapWeatherState(
          status: MapWeatherStatus.error,
          errorMessage: e.statusCode == 408
              ? 'weather_network_timeout'
              : e.statusCode == 429
                  ? 'weather_rate_limited'
                  : e.statusCode == 502
                      ? 'weather_upstream_unavailable'
                      : e.message,
        ),
      );
    } catch (_) {
      if (generation != _requestGeneration) return;
      emit(
        const MapWeatherState(
          status: MapWeatherStatus.error,
          errorMessage: 'weather_fetch_failed',
        ),
      );
    }
  }

  void clear() {
    _debounce?.cancel();
    _requestGeneration++;
    emit(const MapWeatherState());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
