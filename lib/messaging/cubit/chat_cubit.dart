import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:messaging_repository/messaging_repository.dart';

enum ChatStatus { initial, loading, loaded, sending, error }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.currentUserId,
    this.errorMessage,
  });

  final ChatStatus status;
  final List<ChatMessage> messages;
  final String? currentUserId;
  final String? errorMessage;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? currentUserId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      currentUserId: currentUserId ?? this.currentUserId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, messages, currentUserId, errorMessage];
}

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required MessagingRepository messagingRepository,
    required AuthRepository authRepository,
    required this.threadId,
  })  : _messagingRepository = messagingRepository,
        _authRepository = authRepository,
        super(const ChatState());

  final MessagingRepository _messagingRepository;
  final AuthRepository _authRepository;
  final String threadId;

  Future<void> load() async {
    emit(state.copyWith(status: ChatStatus.loading, clearError: true));
    try {
      final session = await _authRepository.currentSession();
      final messages = await _messagingRepository.messages(threadId);
      emit(
        ChatState(
          status: ChatStatus.loaded,
          messages: messages,
          currentUserId: session?.userId,
        ),
      );
    } on MessagingApiException catch (e) {
      emit(
        ChatState(
          status: ChatStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        const ChatState(
          status: ChatStatus.error,
          errorMessage: 'chat_load_failed',
        ),
      );
    }
  }

  Future<void> send(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    emit(state.copyWith(status: ChatStatus.sending, clearError: true));
    try {
      final message = await _messagingRepository.sendMessage(
        threadId: threadId,
        body: trimmed,
      );
      emit(
        ChatState(
          status: ChatStatus.loaded,
          messages: [...state.messages, message],
          currentUserId: state.currentUserId,
        ),
      );
    } on MessagingApiException catch (e) {
      emit(
        state.copyWith(
          status: ChatStatus.loaded,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ChatStatus.loaded,
          errorMessage: 'chat_send_failed',
        ),
      );
    }
  }
}
