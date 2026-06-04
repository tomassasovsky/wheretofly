import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:social_repository/social_repository.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.posts = const [],
    this.followPending = false,
    this.errorMessage,
  });

  final ProfileStatus status;
  final SocialProfile? profile;
  final List<SocialPost> posts;
  final bool followPending;
  final String? errorMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    SocialProfile? profile,
    List<SocialPost>? posts,
    bool? followPending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      posts: posts ?? this.posts,
      followPending: followPending ?? this.followPending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, profile, posts, followPending, errorMessage];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required SocialRepository socialRepository,
    required this.handle,
  })  : _socialRepository = socialRepository,
        super(const ProfileState());

  final SocialRepository _socialRepository;
  final String handle;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final profile = await _socialRepository.profile(handle);
      final posts = await _socialRepository.userPosts(handle);
      emit(
        ProfileState(
          status: ProfileStatus.loaded,
          profile: profile,
          posts: posts,
        ),
      );
    } on SocialApiException catch (e) {
      emit(
        ProfileState(status: ProfileStatus.error, errorMessage: e.message),
      );
    } catch (_) {
      emit(
        const ProfileState(
          status: ProfileStatus.error,
          errorMessage: 'profile_load_failed',
        ),
      );
    }
  }

  Future<void> follow() async {
    if (state.followPending) return;
    emit(state.copyWith(followPending: true, clearError: true));
    try {
      await _socialRepository.follow(handle);
      emit(state.copyWith(followPending: false));
    } on SocialApiException catch (e) {
      emit(
        state.copyWith(followPending: false, errorMessage: e.message),
      );
    } catch (_) {
      emit(
        state.copyWith(
          followPending: false,
          errorMessage: 'follow_failed',
        ),
      );
    }
  }
}
