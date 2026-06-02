import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';

void main() {
  group('SettingsCubit', () {
    late SettingsRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = SettingsRepository(
        Storage(await SharedPreferences.getInstance()),
      );
    });

    blocTest<SettingsCubit, SettingsState>(
      'setLanguage persists locale code',
      build: () => SettingsCubit(repository),
      act: (cubit) => cubit.setLanguage('es'),
      verify: (_) {
        expect(repository.localeCode, 'es');
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'setThemeMode persists dark theme',
      build: () => SettingsCubit(repository),
      act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
      verify: (cubit) {
        expect(cubit.state.themeMode, ThemeMode.dark);
        expect(repository.themeMode.name, 'dark');
      },
    );
  });
}
