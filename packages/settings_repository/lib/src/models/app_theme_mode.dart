/// Domain representation of the user's theme preference.
///
/// Kept free of Flutter so the repository layer has no UI dependency; the
/// presentation layer maps this to Flutter's `ThemeMode`.
enum AppThemeMode {
  system,
  light,
  dark;

  /// Resolves an [AppThemeMode] from its [name], defaulting to [system].
  static AppThemeMode fromName(String? name) => values.firstWhere(
        (m) => m.name == name,
        orElse: () => AppThemeMode.system,
      );
}
