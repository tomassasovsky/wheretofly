import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:social_repository/social_repository.dart';
import 'package:where_to_fly/social/cubit/post_detail_cubit.dart';

class _MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late SocialRepository repository;

  setUp(() {
    repository = _MockSocialRepository();
  });

  const author = SocialAuthor(handle: 'pilot', displayName: 'Pilot');
  final post = SocialPost(
    id: 'p1',
    caption: 'nice flight',
    createdAt: DateTime(2024),
    author: author,
  );
  final comment = SocialComment(
    id: 'c1',
    postId: 'p1',
    body: 'great',
    createdAt: DateTime(2024),
    author: author,
  );

  PostDetailCubit buildCubit() =>
      PostDetailCubit(socialRepository: repository, postId: 'p1');

  blocTest<PostDetailCubit, PostDetailState>(
    'loads post and comments on success',
    build: () {
      when(() => repository.post('p1')).thenAnswer((_) async => post);
      when(() => repository.comments('p1')).thenAnswer((_) async => [comment]);
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<PostDetailState>()
          .having((s) => s.status, 'status', PostDetailStatus.loading),
      isA<PostDetailState>()
          .having((s) => s.status, 'status', PostDetailStatus.loaded)
          .having((s) => s.post, 'post', post)
          .having((s) => s.comments, 'comments', [comment]),
    ],
  );

  blocTest<PostDetailCubit, PostDetailState>(
    'emits error on SocialApiException',
    build: () {
      when(() => repository.post('p1')).thenThrow(
        const SocialApiException('boom'),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<PostDetailState>()
          .having((s) => s.status, 'status', PostDetailStatus.loading),
      isA<PostDetailState>()
          .having((s) => s.status, 'status', PostDetailStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', 'boom'),
    ],
  );

  blocTest<PostDetailCubit, PostDetailState>(
    'addComment appends the new comment',
    build: () {
      when(
        () => repository.addComment(
          postId: any(named: 'postId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => comment);
      return buildCubit();
    },
    seed: () => PostDetailState(
      status: PostDetailStatus.loaded,
      post: post,
    ),
    act: (cubit) => cubit.addComment('great'),
    expect: () => [
      isA<PostDetailState>().having(
        (s) => s.status,
        'status',
        PostDetailStatus.submittingComment,
      ),
      isA<PostDetailState>()
          .having((s) => s.status, 'status', PostDetailStatus.loaded)
          .having((s) => s.comments, 'comments', [comment]),
    ],
  );
}
