import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:messaging_repository/messaging_repository.dart';

enum NotificationPreferencesStatus { initial, loading, loaded, error }

class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState({
    this.status = NotificationPreferencesStatus.initial,
    this.preferences = const NotificationPreferences(
      follows: true,
      messages: true,
      comments: true,
      weather: true,
    ),
    this.errorMessage,
  });

  final NotificationPreferencesStatus status;
  final NotificationPreferences preferences;
  final String? errorMessage;

  NotificationPreferencesState copyWith({
    NotificationPreferencesStatus? status,
    NotificationPreferences? preferences,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationPreferencesState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, preferences, errorMessage];
}

class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit({
    required MessagingRepository messagingRepository,
  })  : _messagingRepository = messagingRepository,
        super(const NotificationPreferencesState());

  final MessagingRepository _messagingRepository;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: NotificationPreferencesStatus.loading,
        clearError: true,
      ),
    );
    try {
      final prefs = await _messagingRepository.notificationPreferences();
      emit(
        NotificationPreferencesState(
          status: NotificationPreferencesStatus.loaded,
          preferences: prefs,
        ),
      );
    } on MessagingApiException catch (e) {
      emit(
        NotificationPreferencesState(
          status: NotificationPreferencesStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        const NotificationPreferencesState(
          status: NotificationPreferencesStatus.error,
          errorMessage: 'notification_prefs_load_failed',
        ),
      );
    }
  }

  Future<void> update(NotificationPreferences prefs) async {
    emit(state.copyWith(preferences: prefs));
    try {
      final updated =
          await _messagingRepository.updateNotificationPreferences(prefs);
      emit(
        NotificationPreferencesState(
          status: NotificationPreferencesStatus.loaded,
          preferences: updated,
        ),
      );
    } on MessagingApiException catch (e) {
      emit(
        state.copyWith(
          status: NotificationPreferencesStatus.error,
          errorMessage: e.message,
        ),
      );
    }
  }

  void reset() {
    emit(const NotificationPreferencesState());
  }
}
