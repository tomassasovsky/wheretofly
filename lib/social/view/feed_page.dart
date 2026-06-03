import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_repository/social_repository.dart';
import 'package:where_to_fly/app/view/app_shell.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/social/cubit/feed_cubit.dart';
import 'package:where_to_fly/social/view/widgets/reel_feed_item.dart';
import 'package:where_to_fly/social/view/widgets/reel_video_background.dart';

/// Vertical reels feed from followed pilots (photos + videos only).
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FeedCubit(socialRepository: context.read<SocialRepository>())..load(),
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            !previous.isAuthenticated && current.isAuthenticated,
        listener: (context, _) => context.read<FeedCubit>().load(),
        child: const _FeedView(),
      ),
    );
  }
}

class _FeedView extends StatefulWidget {
  const _FeedView();

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  late final PageController _pageController;
  var _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.navFeed,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.socialCreatePostTitle,
            icon: const Icon(Icons.add_box_outlined, color: Colors.white),
            onPressed: () => AppShellTab.goTo(context, AppShellTab.map),
          ),
        ],
      ),
      body: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          switch (state.status) {
            case FeedStatus.loading:
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            case FeedStatus.error:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.errorMessage == 'feed_load_failed'
                            ? l10n.socialFeedLoadFailed
                            : (state.errorMessage ?? l10n.socialFeedLoadFailed),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, authState) {
                          if (authState.isAuthenticated) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: FilledButton(
                              onPressed: () => openLogin(context),
                              child: Text(l10n.authLogIn),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            case FeedStatus.loaded:
              if (state.posts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 56,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.socialFeedEmpty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, authState) {
                            if (authState.isAuthenticated) {
                              return const SizedBox.shrink();
                            }
                            return FilledButton(
                              onPressed: () => openLogin(context),
                              child: Text(l10n.authLogIn),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
              final activeMedia = state.posts[_currentIndex].primaryMedia;
              final activeVideoUrl =
                  (activeMedia?.isVideo ?? false) ? activeMedia!.url : null;

              return Stack(
                fit: StackFit.expand,
                children: [
                  ReelVideoBackground(
                    videoUrl: activeVideoUrl,
                    isActive: true,
                  ),
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: state.posts.length,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      return ReelFeedItem(
                        post: state.posts[index],
                        isActive: index == _currentIndex,
                      );
                    },
                  ),
                  if (state.isStale)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: kToolbarHeight),
                          child: _OfflineFeedBanner(
                            label: l10n.socialFeedOffline,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            case FeedStatus.initial:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

/// A compact pill shown over the reels when the feed is showing cached content
/// after a failed refresh (offline / backend unreachable).
class _OfflineFeedBanner extends StatelessWidget {
  const _OfflineFeedBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
