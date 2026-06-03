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
    this.isStale = false,
  });

  final FeedStatus status;
  final List<SocialPost> posts;
  final String? errorMessage;

  /// True when [posts] are the last successfully loaded set, shown because a
  /// refresh failed (e.g. offline / backend unreachable).
  final bool isStale;

  @override
  List<Object?> get props => [status, posts, errorMessage, isStale];
}

class FeedCubit extends Cubit<FeedState> {
  FeedCubit({required SocialRepository socialRepository})
      : _socialRepository = socialRepository,
        super(const FeedState());

  final SocialRepository _socialRepository;

  /// Last successfully loaded feed, kept so a failed refresh can fall back to
  /// cached content instead of a blank error (offline degraded mode).
  List<SocialPost> _cachedPosts = const [];

  Future<void> load() async {
    emit(FeedState(status: FeedStatus.loading, posts: _cachedPosts));
    try {
      final posts = await _socialRepository.feed();
      _cachedPosts = posts.where((post) => post.hasMedia).toList();
      emit(FeedState(status: FeedStatus.loaded, posts: _cachedPosts));
    } on SocialApiException catch (e) {
      _emitFailure(e.message);
    } catch (_) {
      _emitFailure('feed_load_failed');
    }
  }

  void _emitFailure(String message) {
    if (_cachedPosts.isNotEmpty) {
      // Degrade gracefully: keep showing the cached feed with a stale flag.
      emit(
        FeedState(
          status: FeedStatus.loaded,
          posts: _cachedPosts,
          isStale: true,
        ),
      );
    } else {
      emit(FeedState(status: FeedStatus.error, errorMessage: message));
    }
  }
}
