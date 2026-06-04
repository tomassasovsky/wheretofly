import 'dart:io';

import 'package:flutter/foundation.dart';

/// Production API (home server on aquiles.dev).
const productionApiBaseUrl = 'https://dondevolar.aquiles.dev';

/// Resolves the backend base URL for the current run target.
///
/// Defaults to [productionApiBaseUrl]. Overrides:
///   --dart-define=API_BASE_URL=https://...
///   --dart-define=API_HOST=192.168.x.x  (http://HOST:8080)
///   --dart-define=USE_LOCAL_API=true    (localhost / emulator hosts)
Uri resolveApiBaseUri() {
  const explicit = String.fromEnvironment('API_BASE_URL');
  if (explicit.isNotEmpty) {
    return Uri.parse(explicit);
  }

  const hostOverride = String.fromEnvironment('API_HOST');
  if (hostOverride.isNotEmpty) {
    return Uri(scheme: 'http', host: hostOverride, port: 8080);
  }

  const useLocalApi = bool.fromEnvironment('USE_LOCAL_API');
  if (useLocalApi) {
    return _localDevApiUri();
  }

  return Uri.parse(productionApiBaseUrl);
}

Uri _localDevApiUri() {
  if (kIsWeb) {
    return Uri.parse('http://localhost:8080');
  }

  if (Platform.isAndroid) {
    return Uri.parse('http://10.0.2.2:8080');
  }

  if (Platform.isIOS && _isIosSimulator) {
    return Uri.parse('http://localhost:8080');
  }

  return Uri.parse('http://localhost:8080');
}

bool get _isIosSimulator {
  return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
}

/// True when using local dev API on a physical device (localhost unreachable).
bool get apiBaseUriNeedsPhysicalDeviceOverride {
  if (!const bool.fromEnvironment('USE_LOCAL_API')) return false;
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
  return 'On a physical device with USE_LOCAL_API, run: '
      'flutter run --dart-define=API_BASE_URL=http://<your-mac-ip>:8080 '
      'or drop USE_LOCAL_API to use $productionApiBaseUrl';
}
