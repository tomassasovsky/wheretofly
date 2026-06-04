import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:where_to_fly/map/view/widgets/map_transient_message.dart';

/// Visual intent for transient messages.
enum AppSnackBarIntent { neutral, warning, error, success }

/// Material 3 snack bars (floating, rounded, map-aware margins).
abstract final class AppSnackBar {
  static const _horizontalInset = 16.0;
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarIntent intent = AppSnackBarIntent.neutral,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style = styleFor(intent, colorScheme);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(style.icon, size: 22, color: style.foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: style.foreground,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: style.background,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          margin: _marginFor(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: style.border),
          ),
        ),
      );
  }

  static EdgeInsets _marginFor(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final path = GoRouterState.of(context).uri.path;

    const tabBarHeight = 56.0;
    final bottom = switch (path) {
      // Map messages use [MapTransientMessage] below the search bar.
      '/map' => padding.bottom + 12,
      '/feed' ||
      '/explore' ||
      '/messages' ||
      '/me' =>
        padding.bottom + tabBarHeight + 12,
      _ => padding.bottom + 12,
    };

    return EdgeInsets.fromLTRB(
      _horizontalInset + padding.left,
      0,
      _horizontalInset + padding.right,
      bottom,
    );
  }

  /// Colors and icon for [AppSnackBar] and [MapTransientMessage].
  static AppSnackBarStyle styleFor(
    AppSnackBarIntent intent,
    ColorScheme colorScheme,
  ) {
    return switch (intent) {
      AppSnackBarIntent.neutral => AppSnackBarStyle(
          icon: Icons.info_outline_rounded,
          background: colorScheme.surfaceContainerHigh,
          foreground: colorScheme.onSurface,
          border: colorScheme.outlineVariant,
        ),
      AppSnackBarIntent.warning => AppSnackBarStyle(
          icon: Icons.warning_amber_rounded,
          background: colorScheme.tertiaryContainer,
          foreground: colorScheme.onTertiaryContainer,
          border: colorScheme.tertiary.withValues(alpha: 0.35),
        ),
      AppSnackBarIntent.error => AppSnackBarStyle(
          icon: Icons.error_outline_rounded,
          background: colorScheme.errorContainer,
          foreground: colorScheme.onErrorContainer,
          border: colorScheme.error.withValues(alpha: 0.35),
        ),
      AppSnackBarIntent.success => AppSnackBarStyle(
          icon: Icons.check_circle_outline_rounded,
          background: colorScheme.primaryContainer,
          foreground: colorScheme.onPrimaryContainer,
          border: colorScheme.primary.withValues(alpha: 0.35),
        ),
    };
  }
}

class AppSnackBarStyle {
  const AppSnackBarStyle({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final Color border;
}

/// Convenience for [AppSnackBar.show].
extension AppSnackBarContext on BuildContext {
  void showAppSnackBar(
    String message, {
    AppSnackBarIntent intent = AppSnackBarIntent.neutral,
  }) {
    AppSnackBar.show(this, message: message, intent: intent);
  }
}
