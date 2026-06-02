import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:social_api_client/social_api_client.dart';
import 'package:social_repository/social_repository.dart';
import 'package:where_to_fly/social/cubit/feed_cubit.dart';

class _MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late SocialRepository repository;

  setUp(() {
    repository = _MockSocialRepository();
  });

  final samplePost = SocialPost(
    id: 'post-1',
    caption: 'Good day to fly',
    createdAt: DateTime.utc(2026, 6, 2),
    author: const SocialAuthor(
      handle: 'pilot',
      displayName: 'Pilot',
    ),
    media: const [
      PostMedia(
        id: 'media-1',
        type: PostMediaType.photo,
        url: 'https://picsum.photos/seed/post-1/1080/1920',
      ),
    ],
  );

  blocTest<FeedCubit, FeedState>(
    'loads feed when repository succeeds',
    build: () {
      when(() => repository.feed()).thenAnswer(
        (_) async => [samplePost],
      );
      return FeedCubit(socialRepository: repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<FeedState>().having(
        (s) => s.status,
        'status',
        FeedStatus.loading,
      ),
      isA<FeedState>()
          .having((s) => s.status, 'status', FeedStatus.loaded)
          .having((s) => s.posts, 'posts', [samplePost]),
    ],
  );

  blocTest<FeedCubit, FeedState>(
    'emits error when repository throws SocialApiException',
    build: () {
      when(() => repository.feed()).thenThrow(
        const SocialApiException('Unauthorized', statusCode: 401),
      );
      return FeedCubit(socialRepository: repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<FeedState>().having(
        (s) => s.status,
        'status',
        FeedStatus.loading,
      ),
      isA<FeedState>()
          .having((s) => s.status, 'status', FeedStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', 'Unauthorized'),
    ],
  );
}
