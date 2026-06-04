import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:where_to_fly/bootstrap.dart';

import 'store_screenshot_config.dart';
import 'store_screenshot_weather_repository.dart';

/// App entry for store screenshot integration tests.
Future<void> bootstrapForStoreScreenshots() async {
  await initializeAppPlatform();

  final previousFlutterOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (StoreScreenshotConfig.isBenignFlutterError(details)) {
      return;
    }
    log(details.exceptionAsString(), stackTrace: details.stack);
    previousFlutterOnError?.call(details);
  };

  if (kDebugMode) {
    Bloc.observer = const AppBlocObserver();
  }

  final deps = await buildApp(
    weatherRepository: StoreScreenshotWeatherRepository(),
  );
  const locale = StoreScreenshotConfig.localeCode;
  if (locale.isNotEmpty) {
    await deps.settingsRepository.setLocaleCode(locale);
  }
  await deps.settingsRepository.setThemeMode(AppThemeMode.light);
  runApp(deps.app);
}
