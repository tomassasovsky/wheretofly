import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_repository/weather_repository.dart';

enum WeatherAlertsStatus { initial, loading, loaded, error }

class WeatherAlertsState extends Equatable {
  const WeatherAlertsState({
    this.status = WeatherAlertsStatus.initial,
    this.subscriptions = const [],
    this.errorMessage,
  });

  final WeatherAlertsStatus status;
  final List<WeatherAlertSubscription> subscriptions;
  final String? errorMessage;

  WeatherAlertsState copyWith({
    WeatherAlertsStatus? status,
    List<WeatherAlertSubscription>? subscriptions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WeatherAlertsState(
      status: status ?? this.status,
      subscriptions: subscriptions ?? this.subscriptions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, subscriptions, errorMessage];
}

/// Manages saved weather alert locations for the signed-in user.
class WeatherAlertsCubit extends Cubit<WeatherAlertsState> {
  WeatherAlertsCubit({required WeatherRepository weatherRepository})
      : _weatherRepository = weatherRepository,
        super(const WeatherAlertsState());

  final WeatherRepository _weatherRepository;

  Future<void> load() async {
    emit(state.copyWith(status: WeatherAlertsStatus.loading, clearError: true));
    try {
      final items = await _weatherRepository.listAlertSubscriptions();
      emit(
        WeatherAlertsState(
          status: WeatherAlertsStatus.loaded,
          subscriptions: items,
        ),
      );
    } on WeatherApiException catch (e) {
      emit(
        WeatherAlertsState(
          status: WeatherAlertsStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        const WeatherAlertsState(
          status: WeatherAlertsStatus.error,
          errorMessage: 'weather_alerts_load_failed',
        ),
      );
    }
  }

  Future<bool> save({
    required String label,
    required LatLng point,
    double windThresholdMs = 8,
  }) async {
    try {
      final created = await _weatherRepository.createAlertSubscription(
        label: label,
        point: point,
        windThresholdMs: windThresholdMs,
      );
      emit(
        state.copyWith(
          subscriptions: [created, ...state.subscriptions],
          status: WeatherAlertsStatus.loaded,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> remove(String id) async {
    final previous = state.subscriptions;
    emit(
      state.copyWith(
        subscriptions:
            previous.where((s) => s.id != id).toList(growable: false),
        clearError: true,
      ),
    );
    try {
      await _weatherRepository.deleteAlertSubscription(id);
    } on WeatherApiException catch (e) {
      emit(
        state.copyWith(
          status: WeatherAlertsStatus.error,
          subscriptions: previous,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: WeatherAlertsStatus.error,
          subscriptions: previous,
          errorMessage: 'weather_alerts_remove_failed',
        ),
      );
    }
  }

  void reset() => emit(const WeatherAlertsState());
}
