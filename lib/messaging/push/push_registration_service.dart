import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:messaging_repository/messaging_repository.dart';

String devicePlatformForPush() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS ||
    TargetPlatform.macOS ||
    TargetPlatform.linux ||
    TargetPlatform.windows ||
    TargetPlatform.fuchsia =>
      'ios',
  };
}

/// Registers a device token with the backend.
///
/// FCM stub until Firebase is wired.
class PushRegistrationService {
  PushRegistrationService({
    required MessagingRepository messagingRepository,
    required AuthRepository authRepository,
  })  : _messagingRepository = messagingRepository,
        _authRepository = authRepository;

  final MessagingRepository _messagingRepository;
  final AuthRepository _authRepository;

  String? _lastToken;

  Future<void> registerForCurrentUser() async {
    try {
      final session = await _authRepository.currentSession();
      if (session == null) return;
      final platform = devicePlatformForPush();
      final token = 'dev-stub-$platform-${session.userId ?? session.handle}';
      if (_lastToken == token) return;
      await _messagingRepository.registerDeviceToken(
        token: token,
        platform: platform,
      );
      _lastToken = token;
    } on Object {
      // Push registration is best-effort until FCM is configured.
    }
  }

  Future<void> unregister() async {
    try {
      if (_lastToken == null) return;
      await _messagingRepository.unregisterDeviceToken(token: _lastToken!);
      _lastToken = null;
    } on Object {
      _lastToken = null;
    }
  }
}
