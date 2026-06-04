import 'package:auth_repository/auth_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messaging_repository/messaging_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:where_to_fly/messaging/cubit/chat_cubit.dart';

class _MockMessagingRepository extends Mock implements MessagingRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MessagingRepository messagingRepository;
  late AuthRepository authRepository;

  setUp(() {
    messagingRepository = _MockMessagingRepository();
    authRepository = _MockAuthRepository();
  });

  final message = ChatMessage(
    id: 'm1',
    threadId: 't1',
    senderId: 'u1',
    body: 'hello',
    createdAt: DateTime(2024),
  );

  ChatCubit buildCubit() => ChatCubit(
        messagingRepository: messagingRepository,
        authRepository: authRepository,
        threadId: 't1',
      );

  blocTest<ChatCubit, ChatState>(
    'loads messages on success',
    build: () {
      when(authRepository.currentSession).thenAnswer((_) async => null);
      when(() => messagingRepository.messages('t1'))
          .thenAnswer((_) async => [message]);
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ChatState>().having((s) => s.status, 'status', ChatStatus.loading),
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.loaded)
          .having((s) => s.messages, 'messages', [message]),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'emits error on MessagingApiException',
    build: () {
      when(authRepository.currentSession).thenAnswer((_) async => null);
      when(() => messagingRepository.messages('t1')).thenThrow(
        const MessagingApiException('boom'),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ChatState>().having((s) => s.status, 'status', ChatStatus.loading),
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', 'boom'),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'send ignores blank input',
    build: buildCubit,
    act: (cubit) => cubit.send('   '),
    expect: () => <ChatState>[],
  );

  blocTest<ChatCubit, ChatState>(
    'send appends the new message',
    build: () {
      when(
        () => messagingRepository.sendMessage(
          threadId: any(named: 'threadId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => message);
      return buildCubit();
    },
    act: (cubit) => cubit.send('hello'),
    expect: () => [
      isA<ChatState>().having((s) => s.status, 'status', ChatStatus.sending),
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.loaded)
          .having((s) => s.messages, 'messages', [message]),
    ],
  );
}
