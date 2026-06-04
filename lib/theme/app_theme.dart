import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Material 3 theme aligned with the brand mark (indigo #3B0297).
///
/// iOS-leaning transitions, tuned surfaces, and map zone colours that read
/// on light and dark basemaps.
abstract final class AppTheme {
  /// Brand indigo (matches the app icon).
  static const seed = Color(0xFF3B0297);
  static const _accent = Color(0xFF7C3AED);

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  /// Opaque fill for floating map controls (search, FABs, cards).
  static Color mapOverlaySurface(Brightness brightness) {
    return brightness == Brightness.light
        ? const Color(0xFFFBFAFE)
        : const Color(0xFF221E2B);
  }

  /// Muted chip / inactive control surface on the map.
  static Color mapOverlayMuted(Brightness brightness) {
    return brightness == Brightness.light
        ? const Color(0xFFEFEAF7)
        : const Color(0xFF2F2B3A);
  }

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(
      secondary: _accent,
      surface: mapOverlaySurface(brightness),
      surfaceContainerHighest: mapOverlayMuted(brightness),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF121016) : mapOverlaySurface(brightness),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
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
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
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
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
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
