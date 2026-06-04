import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messaging_repository/messaging_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:where_to_fly/messaging/cubit/threads_cubit.dart';

class _MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MessagingRepository repository;

  setUp(() {
    repository = _MockMessagingRepository();
  });

  const thread = ChatThread(id: 't1', isGroup: false);

  blocTest<ThreadsCubit, ThreadsState>(
    'loads threads on success',
    build: () {
      when(repository.threads).thenAnswer((_) async => [thread]);
      return ThreadsCubit(messagingRepository: repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ThreadsState>()
          .having((s) => s.status, 'status', ThreadsStatus.loading),
      isA<ThreadsState>()
          .having((s) => s.status, 'status', ThreadsStatus.loaded)
          .having((s) => s.threads, 'threads', [thread]),
    ],
  );

  blocTest<ThreadsCubit, ThreadsState>(
    'emits error on MessagingApiException',
    build: () {
      when(repository.threads).thenThrow(
        const MessagingApiException('boom', statusCode: 500),
      );
      return ThreadsCubit(messagingRepository: repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ThreadsState>()
          .having((s) => s.status, 'status', ThreadsStatus.loading),
      isA<ThreadsState>()
          .having((s) => s.status, 'status', ThreadsStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', 'boom'),
    ],
  );
}
