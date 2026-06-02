import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:social_api_client/social_api_client.dart';
import 'package:social_repository/social_repository.dart';

enum PostDetailStatus { initial, loading, loaded, error, submittingComment }

class PostDetailState extends Equatable {
  const PostDetailState({
    this.status = PostDetailStatus.initial,
    this.post,
    this.comments = const [],
    this.errorMessage,
  });

  final PostDetailStatus status;
  final SocialPost? post;
  final List<SocialComment> comments;
  final String? errorMessage;

  PostDetailState copyWith({
    PostDetailStatus? status,
    SocialPost? post,
    List<SocialComment>? comments,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PostDetailState(
      status: status ?? this.status,
      post: post ?? this.post,
      comments: comments ?? this.comments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, post, comments, errorMessage];
}

class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit({
    required SocialRepository socialRepository,
    required this.postId,
  })  : _socialRepository = socialRepository,
        super(const PostDetailState());

  final SocialRepository _socialRepository;
  final String postId;

  Future<void> load() async {
    emit(state.copyWith(status: PostDetailStatus.loading, clearError: true));
    try {
      final post = await _socialRepository.post(postId);
      final comments = await _socialRepository.comments(postId);
      emit(
        PostDetailState(
          status: PostDetailStatus.loaded,
          post: post,
          comments: comments,
        ),
      );
    } on SocialApiException catch (e) {
      emit(
        PostDetailState(
            status: PostDetailStatus.error, errorMessage: e.message,),
      );
    } catch (_) {
      emit(
        const PostDetailState(
          status: PostDetailStatus.error,
          errorMessage: 'post_load_failed',
        ),
      );
    }
  }

  Future<void> addComment(String body) async {
    if (body.trim().isEmpty) return;
    emit(state.copyWith(status: PostDetailStatus.submittingComment));
    try {
      final comment = await _socialRepository.addComment(
        postId: postId,
        body: body.trim(),
      );
      emit(
        state.copyWith(
          status: PostDetailStatus.loaded,
          comments: [...state.comments, comment],
        ),
      );
    } on SocialApiException catch (e) {
      emit(
        state.copyWith(
          status: PostDetailStatus.loaded,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PostDetailStatus.loaded,
          errorMessage: 'comment_failed',
        ),
      );
    }
  }
}
