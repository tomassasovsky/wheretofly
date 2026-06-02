import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:social_api_client/social_api_client.dart';
import 'package:social_repository/social_repository.dart';

enum FeedStatus { initial, loading, loaded, error }

class FeedState extends Equatable {
  const FeedState({
    this.status = FeedStatus.initial,
    this.posts = const [],
    this.errorMessage,
  });

  final FeedStatus status;
  final List<SocialPost> posts;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, posts, errorMessage];
}

class FeedCubit extends Cubit<FeedState> {
  FeedCubit({required SocialRepository socialRepository})
      : _socialRepository = socialRepository,
        super(const FeedState());

  final SocialRepository _socialRepository;

  Future<void> load() async {
    emit(const FeedState(status: FeedStatus.loading));
    try {
      final posts = await _socialRepository.feed();
      emit(
        FeedState(
          status: FeedStatus.loaded,
          posts: posts.where((post) => post.hasMedia).toList(),
        ),
      );
    } on SocialApiException catch (e) {
      emit(FeedState(status: FeedStatus.error, errorMessage: e.message));
    } catch (_) {
      emit(
        const FeedState(
          status: FeedStatus.error,
          errorMessage: 'feed_load_failed',
        ),
      );
    }
  }
}
