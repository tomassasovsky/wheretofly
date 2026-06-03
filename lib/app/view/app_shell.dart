import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';

/// Instagram-style bottom navigation wrapping the main app tabs.
class AppShell extends StatefulWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureGuestOnMapBranch();
  }

  void _ensureGuestOnMapBranch() {
    final isGuest = !context.read<AuthCubit>().state.isAuthenticated;
    if (!isGuest) return;
    if (widget.navigationShell.currentIndex == AppShellTab.map) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthCubit>().state.isAuthenticated) return;
      widget.navigationShell.goBranch(
        AppShellTab.map,
        initialLocation: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.isAuthenticated != current.isAuthenticated,
      listener: (context, state) => _ensureGuestOnMapBranch(),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isGuest = !authState.isAuthenticated;

          return Scaffold(
            body: widget.navigationShell,
            bottomNavigationBar: isGuest
                ? null
                : NavigationBarTheme(
                    data: NavigationBarThemeData(
                      height: 56,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysHide,
                      indicatorColor: Colors.transparent,
                      iconTheme: WidgetStateProperty.resolveWith((states) {
                        final selected = states.contains(WidgetState.selected);
                        return IconThemeData(
                          size: 26,
                          color: selected
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        );
                      }),
                    ),
                    child: NavigationBar(
                      selectedIndex: widget.navigationShell.currentIndex,
                      onDestinationSelected: (index) {
                        widget.navigationShell.goBranch(
                          index,
                          initialLocation:
                              index == widget.navigationShell.currentIndex,
                        );
                      },
                      destinations: [
                        NavigationDestination(
                          icon: const Icon(Icons.home_outlined),
                          selectedIcon: const Icon(Icons.home),
                          label: l10n.navFeed,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.search),
                          selectedIcon: const Icon(Icons.search),
                          label: l10n.navExplore,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.map_outlined),
                          selectedIcon: const Icon(Icons.map),
                          label: l10n.navMap,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.chat_bubble_outline),
                          selectedIcon: const Icon(Icons.chat_bubble),
                          label: l10n.navMessages,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.person_outline),
                          selectedIcon: const Icon(Icons.person),
                          label: l10n.navProfile,
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// Branch index helpers for programmatic tab switches.
abstract final class AppShellTab {
  static const feed = 0;
  static const explore = 1;
  static const map = 2;
  static const messages = 3;
  static const profile = 4;

  static void goTo(BuildContext context, int index) {
    final shell = StatefulNavigationShell.maybeOf(context);
    shell?.goBranch(index);
  }
}
