import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messaging_repository/messaging_repository.dart';
import 'package:social_repository/social_repository.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/social/cubit/profile_cubit.dart';
import 'package:where_to_fly/social/view/widgets/profile_media_grid.dart';
import 'package:where_to_fly/theme/app_snack_bar.dart';

/// Public pilot profile and posts.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.handle,
    this.isOwnProfile = false,
    super.key,
  });

  final String handle;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(
        socialRepository: context.read<SocialRepository>(),
        handle: handle,
      )..load(),
      child: _ProfileView(handle: handle, isOwnProfile: isOwnProfile),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.handle,
    required this.isOwnProfile,
  });

  final String handle;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isOwnProfile ? l10n.navProfile : '@$handle',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          if (isOwnProfile)
            IconButton(
              tooltip: l10n.settings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => const SettingsRoute().push<void>(context),
            ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          switch (state.status) {
            case ProfileStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case ProfileStatus.error:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.errorMessage == 'profile_load_failed'
                        ? l10n.socialProfileLoadFailed
                        : (state.errorMessage ?? l10n.socialProfileLoadFailed),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            case ProfileStatus.loaded:
              final profile = state.profile!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatColumn(
                              count: state.posts.length.toString(),
                              label: l10n.socialPosts,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '@${profile.handle}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(profile.bio),
                  ],
                  if (!isOwnProfile) ...[
                    const SizedBox(height: 16),
                    _ProfileActions(
                      profile: profile,
                      followPending: state.followPending,
                      onFollow: () => context.read<ProfileCubit>().follow(),
                      followLabel: profile.requiresApprovalToFollow
                          ? l10n.socialFollowRequest
                          : l10n.socialFollow,
                    ),
                  ],
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.35),
                  ),
                  if (state.posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(child: Text(l10n.socialProfilePostsEmpty)),
                    )
                  else
                    ProfileMediaGrid(posts: state.posts),
                ],
              );
            case ProfileStatus.initial:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

class _ProfileActions extends StatefulWidget {
  const _ProfileActions({
    required this.profile,
    required this.followPending,
    required this.onFollow,
    required this.followLabel,
  });

  final SocialProfile profile;
  final bool followPending;
  final VoidCallback onFollow;
  final String followLabel;

  @override
  State<_ProfileActions> createState() => _ProfileActionsState();
}

class _ProfileActionsState extends State<_ProfileActions> {
  bool _messagePending = false;

  Future<void> _openChat() async {
    setState(() => _messagePending = true);
    try {
      final thread =
          await context.read<MessagingRepository>().createDirectThread(
                userId: widget.profile.id,
              );
      if (!mounted) return;
      await ThreadRoute(
        threadId: thread.id,
        $extra: widget.profile.displayName,
      ).push<void>(context);
    } catch (_) {
      if (!mounted) return;
      context.showAppSnackBar(
        AppLocalizations.of(context).socialMessageOpenFailed,
        intent: AppSnackBarIntent.error,
      );
    } finally {
      if (mounted) setState(() => _messagePending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: widget.followPending ? null : widget.onFollow,
            child: Text(widget.followLabel),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _messagePending ? null : _openChat,
            child: _messagePending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.socialMessage),
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.count, required this.label});

  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
