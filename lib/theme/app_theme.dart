import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Material 3 theme with an iOS-leaning aesthetic (Cupertino page transitions,
/// flat app bars) and full light + dark support.
abstract final class AppTheme {
  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    const seed = Color.fromARGB(255, 59, 2, 151); // iOS system blue.

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      // iOS-style page transitions on every platform.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Colour used to draw a zone of a given [category] on the map.
  static Color zoneColor(ZoneCategory category) {
    switch (category) {
      case ZoneCategory.controlledAirspace:
        return const Color(0xFFFB8C00); // orange
      case ZoneCategory.prohibited:
        return const Color(0xFFD32F2F); // red
      case ZoneCategory.restricted:
        return const Color(0xFFC2185B); // pink-red
      case ZoneCategory.nationalPark:
        return const Color(0xFF2E7D32); // green
      case ZoneCategory.sensitiveInfrastructure:
        return const Color(0xFF6A1B9A); // purple
      case ZoneCategory.open:
        return const Color(0xFF0A84FF); // blue
    }
  }
}
