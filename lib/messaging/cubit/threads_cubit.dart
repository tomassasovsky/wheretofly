import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:messaging_api_client/messaging_api_client.dart';
import 'package:messaging_repository/messaging_repository.dart';

enum ThreadsStatus { initial, loading, loaded, error }

class ThreadsState extends Equatable {
  const ThreadsState({
    this.status = ThreadsStatus.initial,
    this.threads = const [],
    this.errorMessage,
  });

  final ThreadsStatus status;
  final List<ChatThread> threads;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, threads, errorMessage];
}

class ThreadsCubit extends Cubit<ThreadsState> {
  ThreadsCubit({required MessagingRepository messagingRepository})
      : _messagingRepository = messagingRepository,
        super(const ThreadsState());

  final MessagingRepository _messagingRepository;

  Future<void> load() async {
    emit(const ThreadsState(status: ThreadsStatus.loading));
    try {
      final threads = await _messagingRepository.threads();
      emit(ThreadsState(status: ThreadsStatus.loaded, threads: threads));
    } on MessagingApiException catch (e) {
      emit(ThreadsState(status: ThreadsStatus.error, errorMessage: e.message));
    } catch (_) {
      emit(
        const ThreadsState(
          status: ThreadsStatus.error,
          errorMessage: 'threads_load_failed',
        ),
      );
    }
  }
}
