import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messaging_api_client/messaging_api_client.dart';
import 'package:messaging_repository/messaging_repository.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/messaging/cubit/threads_cubit.dart';

/// Direct messages inbox.
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThreadsCubit(
        messagingRepository: context.read<MessagingRepository>(),
      )..load(),
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            !previous.isAuthenticated && current.isAuthenticated,
        listener: (context, _) => context.read<ThreadsCubit>().load(),
        child: const _MessagesView(),
      ),
    );
  }
}

class _MessagesView extends StatelessWidget {
  const _MessagesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navMessages),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (!authState.isAuthenticated) {
            return _EmptyState(
              icon: Icons.lock_outline,
              title: l10n.messagesRequiresAuth,
              actionLabel: l10n.authLogIn,
              onAction: () => openLogin(context),
            );
          }
          return BlocBuilder<ThreadsCubit, ThreadsState>(
            builder: (context, state) {
              switch (state.status) {
                case ThreadsStatus.loading:
                  return const Center(child: CircularProgressIndicator());
                case ThreadsStatus.error:
                  return Center(
                    child: Text(
                      state.errorMessage == 'threads_load_failed'
                          ? l10n.messagesLoadFailed
                          : (state.errorMessage ?? l10n.messagesLoadFailed),
                    ),
                  );
                case ThreadsStatus.loaded:
                  if (state.threads.isEmpty) {
                    return _EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: l10n.messagesEmpty,
                      subtitle: l10n.messagesEmptySubtitle,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<ThreadsCubit>().load(),
                    child: ListView.separated(
                      itemCount: state.threads.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 72,
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.35),
                      ),
                      itemBuilder: (context, index) {
                        final thread = state.threads[index];
                        return _ThreadTile(thread: thread);
                      },
                    ),
                  );
                case ThreadsStatus.initial:
                  return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = thread.displayTitle();
    final subtitle = thread.lastMessageBody ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          title.isNotEmpty ? title[0].toUpperCase() : '?',
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: () => ThreadRoute(
        threadId: thread.id,
        $extra: title,
      ).push<void>(context),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
