import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:social_repository/social_repository.dart';
import 'package:where_to_fly/social/cubit/profile_cubit.dart';

class _MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late SocialRepository repository;

  setUp(() {
    repository = _MockSocialRepository();
  });

  final profile = SocialProfile(
    id: 'u1',
    handle: 'pilot',
    displayName: 'Pilot',
    bio: '',
    followMode: 'open',
    createdAt: DateTime.utc(2026),
  );

  blocTest<ProfileCubit, ProfileState>(
    'loads profile and posts on success',
    build: () {
      when(() => repository.profile('pilot')).thenAnswer((_) async => profile);
      when(() => repository.userPosts('pilot'))
          .thenAnswer((_) async => const []);
      return ProfileCubit(socialRepository: repository, handle: 'pilot');
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ProfileState>()
          .having((s) => s.status, 'status', ProfileStatus.loading),
      isA<ProfileState>()
          .having((s) => s.status, 'status', ProfileStatus.loaded)
          .having((s) => s.profile, 'profile', profile),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'emits error on SocialApiException',
    build: () {
      when(() => repository.profile('pilot')).thenThrow(
        const SocialApiException('nope', statusCode: 404),
      );
      return ProfileCubit(socialRepository: repository, handle: 'pilot');
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ProfileState>()
          .having((s) => s.status, 'status', ProfileStatus.loading),
      isA<ProfileState>()
          .having((s) => s.status, 'status', ProfileStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', 'nope'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'follow toggles followPending true then false on success',
    build: () {
      when(() => repository.follow('pilot')).thenAnswer((_) async {});
      return ProfileCubit(socialRepository: repository, handle: 'pilot');
    },
    act: (cubit) => cubit.follow(),
    expect: () => [
      isA<ProfileState>().having((s) => s.followPending, 'followPending', true),
      isA<ProfileState>()
          .having((s) => s.followPending, 'followPending', false),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'follow is a no-op while a follow is already pending',
    build: () => ProfileCubit(socialRepository: repository, handle: 'pilot'),
    seed: () => const ProfileState(followPending: true),
    act: (cubit) => cubit.follow(),
    expect: () => <ProfileState>[],
  );
}
