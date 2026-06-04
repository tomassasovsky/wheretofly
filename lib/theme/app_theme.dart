import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Violet theme — pure white light mode, near-black dark mode.
///
/// Light: pure white surfaces (#FFFFFF), deep violet primary
/// (#4A1A8F, ~11:1 AAA).
/// Dark: near-black surfaces (#0A0714), lavender primary (#C4B5FD, ~11:1 AAA).
abstract final class AppTheme {
  /// Violet seed.
  static const seed = Color(0xFF6D28D9);

  // Light mode — deep violet reads at 11:1 on white.
  static const _primaryLight = Color(0xFF4A1A8F);
  static const _secondaryLight = Color(0xFF6D28D9);

  // Dark mode — lavender reads at 11:1 on near-black.
  static const _primaryDark = Color(0xFFC4B5FD);
  static const _secondaryDark = Color(0xFFA78BFA);

  // Explicit border colour that meets 3:1 on white (WCAG 1.4.11).
  static const _borderLight = Color(0xFF6B6080); // ~5.8:1 on white

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  /// Opaque fill for floating map controls (search, FABs, cards).
  static Color mapOverlaySurface(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF0A0714) // near-black purple
        : Colors.white;
  }

  /// Muted chip / inactive control surface on the map.
  static Color mapOverlayMuted(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF130D20) // deep void
        : const Color(0xFFF5F5F5); // light grey
  }

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? _primaryDark : _primaryLight,
      onPrimary: isDark ? const Color(0xFF1A0050) : Colors.white,
      secondary: isDark ? _secondaryDark : _secondaryLight,
      onSecondary: isDark ? const Color(0xFF1A0060) : Colors.white,
      surface: mapOverlaySurface(brightness),
      surfaceContainerHighest: mapOverlayMuted(brightness),
      // Explicit onSurface tokens to guarantee AAA 7:1 on all surfaces.
      onSurface: isDark ? const Color(0xFFF5F3FF) : const Color(0xFF0D0520),
      onSurfaceVariant:
          isDark ? const Color(0xFFD4CAFE) : const Color(0xFF3B1A6E),
    );

    final borderColor = isDark ? scheme.outlineVariant : _borderLight;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF060410) : Colors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _AccessibleCupertinoTransition(),
          TargetPlatform.iOS: _AccessibleCupertinoTransition(),
          TargetPlatform.macOS: _AccessibleCupertinoTransition(),
        },
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.6 : 0.7,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.primary,
        elevation: 2,
        focusElevation: 2,
        highlightElevation: 3,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mapOverlayMuted(brightness),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        space: 1,
        thickness: 1,
      ),
    );
  }

  /// Colour used to draw a zone of a given [category] on the map.
  /// Deeper tones read better over satellite and street basemaps.
  static Color zoneColor(ZoneCategory category) {
    switch (category) {
      case ZoneCategory.controlledAirspace:
        return const Color(0xFFFB8C00);
      case ZoneCategory.prohibited:
        return const Color(0xFFD32F2F);
      case ZoneCategory.restricted:
        return const Color(0xFFC2185B);
      case ZoneCategory.nationalPark:
        return const Color(0xFF2E7D32);
      case ZoneCategory.sensitiveInfrastructure:
        return const Color(0xFF6A1B9A);
      case ZoneCategory.open:
        return const Color(0xFF0A84FF);
    }
  }
}

/// Slides with Cupertino animation, skips it when reduced motion is enabled.
class _AccessibleCupertinoTransition extends PageTransitionsBuilder {
  // ignore: prefer_const_constructors_in_immutables
  _AccessibleCupertinoTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return const CupertinoPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
