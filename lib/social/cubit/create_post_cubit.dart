import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:social_repository/social_repository.dart';
import 'package:where_to_fly/social/create_post_draft.dart';

enum CreatePostStatus { initial, submitting, success, error }

class CreatePostState extends Equatable {
  const CreatePostState({
    this.status = CreatePostStatus.initial,
    this.createdPost,
    this.errorMessage,
  });

  final CreatePostStatus status;
  final SocialPost? createdPost;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, createdPost, errorMessage];
}

class CreatePostCubit extends Cubit<CreatePostState> {
  CreatePostCubit({
    required SocialRepository socialRepository,
    required this.draft,
  })  : _socialRepository = socialRepository,
        super(const CreatePostState());

  final SocialRepository _socialRepository;
  final CreatePostDraft draft;

  Future<void> submit(String caption) async {
    emit(const CreatePostState(status: CreatePostStatus.submitting));
    try {
      final seed = '${draft.point.latitude.toStringAsFixed(4)}_'
          '${draft.point.longitude.toStringAsFixed(4)}';
      final post = await _socialRepository.createPost(
        caption: caption.trim(),
        locationLat: draft.point.latitude,
        locationLon: draft.point.longitude,
        verdictSnapshot: draft.toVerdictSnapshot(),
        zoneVersion: draft.zoneVersion,
        media: [
          {
            'mediaType': 'photo',
            'storageKey': 'https://picsum.photos/seed/$seed/1080/1920',
            'mimeType': 'image/jpeg',
            'sizeBytes': 0,
          },
        ],
      );
      emit(
        CreatePostState(status: CreatePostStatus.success, createdPost: post),
      );
    } on SocialApiException catch (e) {
      emit(
        CreatePostState(
          status: CreatePostStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        const CreatePostState(
          status: CreatePostStatus.error,
          errorMessage: 'post_create_failed',
        ),
      );
    }
  }
}
