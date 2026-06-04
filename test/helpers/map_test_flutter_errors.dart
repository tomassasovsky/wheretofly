import 'package:flutter/foundation.dart';

FlutterExceptionHandler? _savedFlutterOnError;

bool isBenignMapTestFlutterError(FlutterErrorDetails details) {
  final message = details.exceptionAsString();
  final library = details.library ?? '';
  return library == 'image resource service' ||
      message.contains('ClientException') ||
      message.contains('HTTP request failed') ||
      message.contains('ImageCodec') ||
      message.contains('NetworkImageLoadException') ||
      message.contains('Multiple exceptions');
}

void installMapTestFlutterErrorHandler() {
  _savedFlutterOnError ??= FlutterError.onError;
  FlutterError.onError = (details) {
    if (isBenignMapTestFlutterError(details)) return;
    _savedFlutterOnError?.call(details);
  };
}

void restoreMapTestFlutterErrorHandler() {
  if (_savedFlutterOnError != null) {
    FlutterError.onError = _savedFlutterOnError;
    _savedFlutterOnError = null;
  }
}
