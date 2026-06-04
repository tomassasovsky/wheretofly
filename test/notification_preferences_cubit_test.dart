import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messaging_repository/messaging_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:where_to_fly/messaging/cubit/notification_preferences_cubit.dart';

class _MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MessagingRepository repository;

  setUp(() {
    repository = _MockMessagingRepository();
    registerFallbackValue(
      const NotificationPreferences(
        follows: true,
        messages: true,
        comments: true,
        weather: true,
      ),
    );
  });

  const prefs = NotificationPreferences(
    follows: false,
    messages: true,
    comments: true,
    weather: true,
  );

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'loads preferences on success',
    build: () {
      when(repository.notificationPreferences).thenAnswer((_) async => prefs);
      return NotificationPreferencesCubit(messagingRepository: repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<NotificationPreferencesState>().having(
        (s) => s.status,
        'status',
        NotificationPreferencesStatus.loading,
      ),
      isA<NotificationPreferencesState>()
          .having(
            (s) => s.status,
            'status',
            NotificationPreferencesStatus.loaded,
          )
          .having((s) => s.preferences.follows, 'follows', false),
    ],
  );

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'emits error on MessagingApiException',
    build: () {
      when(repository.notificationPreferences).thenThrow(
        const MessagingApiException('boom'),
      );
      return NotificationPreferencesCubit(messagingRepository: repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<NotificationPreferencesState>().having(
        (s) => s.status,
        'status',
        NotificationPreferencesStatus.loading,
      ),
      isA<NotificationPreferencesState>().having(
        (s) => s.status,
        'status',
        NotificationPreferencesStatus.error,
      ),
    ],
  );

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'update optimistically applies then confirms loaded',
    build: () {
      when(() => repository.updateNotificationPreferences(any()))
          .thenAnswer((_) async => prefs);
      return NotificationPreferencesCubit(messagingRepository: repository);
    },
    act: (cubit) => cubit.update(prefs),
    expect: () => [
      isA<NotificationPreferencesState>()
          .having((s) => s.preferences.follows, 'follows', false),
      isA<NotificationPreferencesState>().having(
        (s) => s.status,
        'status',
        NotificationPreferencesStatus.loaded,
      ),
    ],
  );
}
