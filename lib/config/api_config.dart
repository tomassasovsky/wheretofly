import 'dart:io';

import 'package:flutter/foundation.dart';

/// Resolves the backend base URL for the current run target.
///
/// Override at build time when needed:
///   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8080
///
/// On a physical phone/tablet, `localhost` points at the device itself — use
/// your Mac's LAN IP (same Wi‑Fi) or run `./scripts/flutter_run_dev.sh`.
Uri resolveApiBaseUri() {
  const explicit = String.fromEnvironment('API_BASE_URL');
  if (explicit.isNotEmpty) {
    return Uri.parse(explicit);
  }

  const hostOverride = String.fromEnvironment('API_HOST');
  if (hostOverride.isNotEmpty) {
    return Uri(scheme: 'http', host: hostOverride, port: 8080);
  }

  if (kIsWeb) {
    return Uri.parse('http://localhost:8080');
  }

  if (Platform.isAndroid) {
    // Android emulator maps the host machine to 10.0.2.2.
    return Uri.parse('http://10.0.2.2:8080');
  }

  if (Platform.isIOS && _isIosSimulator) {
    return Uri.parse('http://localhost:8080');
  }

  // macOS desktop / Linux / Windows dev builds.
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    return Uri.parse('http://localhost:8080');
  }

  // Physical iOS/Android device — localhost will not reach the dev machine.
  return Uri.parse('http://localhost:8080');
}

bool get _isIosSimulator {
  return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
}

/// True when the app likely cannot reach a Mac-hosted backend at localhost.
bool get apiBaseUriNeedsPhysicalDeviceOverride {
  if (kIsWeb) return false;
  const explicit = String.fromEnvironment('API_BASE_URL');
  if (explicit.isNotEmpty) return false;
  const hostOverride = String.fromEnvironment('API_HOST');
  if (hostOverride.isNotEmpty) return false;
  if (Platform.isIOS && !_isIosSimulator) return true;
  if (Platform.isAndroid && !_isAndroidEmulator) return true;
  return false;
}

bool get _isAndroidEmulator {
  return Platform.environment.containsKey('ANDROID_EMULATOR') ||
      (Platform.environment['ANDROID_AVD_HOME']?.isNotEmpty ?? false);
}

String physicalDeviceApiHint() {
  return 'On a physical device, run: '
      'flutter run --dart-define=API_BASE_URL=http://<your-mac-ip>:8080';
}
