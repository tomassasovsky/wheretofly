import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:settings_repository/settings_repository.dart';

/// Business logic: app-wide settings that affect the whole widget tree — the
/// selected [locale] (null = follow device) and the Flutter [themeMode].
///
/// Maps the repository's domain [AppThemeMode] to Flutter's [ThemeMode] so the
/// repository layer stays free of Flutter.
class SettingsState extends Equatable {
  const SettingsState({this.locale, this.themeMode = ThemeMode.system});

  final Locale? locale;
  final ThemeMode themeMode;

  SettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool clearLocale = false,
  }) {
    return SettingsState(
      locale: clearLocale ? null : (locale ?? this.locale),
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [locale, themeMode];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository)
      : super(
          SettingsState(
            locale: _repository.localeCode == null
                ? null
                : Locale(_repository.localeCode!),
            themeMode: _toThemeMode(_repository.themeMode),
          ),
        );

  final SettingsRepository _repository;

  /// Sets the app language. Pass null to follow the device locale.
  Future<void> setLanguage(String? code) async {
    await _repository.setLocaleCode(code);
    emit(
      code == null
          ? state.copyWith(clearLocale: true)
          : state.copyWith(locale: Locale(code)),
    );
  }

  /// Sets the app theme mode (system / light / dark).
  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(_toAppThemeMode(mode));
    emit(state.copyWith(themeMode: mode));
  }

  static ThemeMode _toThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  static AppThemeMode _toAppThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return AppThemeMode.system;
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
    }
  }
}
