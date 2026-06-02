import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:social_repository/social_repository.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/social/create_post_draft.dart';
import 'package:where_to_fly/social/cubit/create_post_cubit.dart';

/// Compose a post from a map fly-check snapshot.
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({required this.draft, super.key});

  final CreatePostDraft draft;

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreatePostCubit(
        socialRepository: context.read<SocialRepository>(),
        draft: widget.draft,
      ),
      child: BlocConsumer<CreatePostCubit, CreatePostState>(
        listenWhen: (previous, current) =>
            previous.status != CreatePostStatus.success &&
            current.status == CreatePostStatus.success,
        listener: (context, state) {
          if (context.mounted) context.pop();
        },
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final submitting = state.status == CreatePostStatus.submitting;
          return Scaffold(
            appBar: AppBar(title: Text(l10n.socialCreatePostTitle)),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.socialCreatePostMediaHint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.socialCreatePostHint),
                const SizedBox(height: 12),
                TextField(
                  controller: _captionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.socialCaptionLabel,
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () => context
                          .read<CreatePostCubit>()
                          .submit(_captionController.text),
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.socialPublish),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
