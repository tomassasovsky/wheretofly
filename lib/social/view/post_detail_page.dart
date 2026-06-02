import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_repository/social_repository.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/social/cubit/post_detail_cubit.dart';
import 'package:where_to_fly/social/view/widgets/post_media_view.dart';

/// Single post with comments.
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({required this.postId, super.key});

  final String postId;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PostDetailCubit(
        socialRepository: context.read<SocialRepository>(),
        postId: widget.postId,
      )..load(),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            appBar: AppBar(title: Text(l10n.socialPostTitle)),
            body: BlocConsumer<PostDetailCubit, PostDetailState>(
              listener: (context, state) {
                if (state.status == PostDetailStatus.loaded &&
                    state.errorMessage == null &&
                    _commentController.text.isNotEmpty) {
                  _commentController.clear();
                }
              },
              builder: (context, state) {
                if (state.status == PostDetailStatus.loading ||
                    state.status == PostDetailStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == PostDetailStatus.error ||
                    state.post == null) {
                  return Center(child: Text(l10n.socialPostLoadFailed));
                }
                final post = state.post!;
                final media = post.primaryMedia;
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (media != null)
                            AspectRatio(
                              aspectRatio: 9 / 16,
                              child: PostMediaView(
                                media: media,
                                isActive: true,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () => ProfileRoute(
                                    handle: post.author.handle,
                                  ).push<void>(context),
                                  child: Text(
                                    post.author.displayName,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                if (post.caption.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(post.caption),
                                ],
                                const Divider(height: 32),
                                Text(
                                  l10n.socialComments,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                if (state.comments.isEmpty)
                                  Text(l10n.socialCommentsEmpty)
                                else
                                  ...state.comments.map(
                                    (comment) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(comment.author.displayName),
                                      subtitle: Text(comment.body),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: l10n.socialCommentHint,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: state.status ==
                                      PostDetailStatus.submittingComment
                                  ? null
                                  : () => context
                                      .read<PostDetailCubit>()
                                      .addComment(_commentController.text),
                              icon: const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
