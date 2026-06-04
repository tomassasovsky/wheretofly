import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host-side driver: writes integration_test screenshots to
/// `STORE_SCREENSHOT_DIR` (defaults to `<project>/docs/screenshots`).
Future<void> main() async {
  final root =
      Platform.environment['STORE_SCREENSHOT_ROOT'] ?? Directory.current.path;
  final outDir =
      Platform.environment['STORE_SCREENSHOT_DIR'] ?? '$root/docs/screenshots';

  try {
    await integrationDriver(
      onScreenshot: (
        String name,
        List<int> bytes, [
        Map<String, Object?>? args,
      ]) async {
        final dir = Directory(outDir);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final file = File('$outDir/$name.png');
        await file.writeAsBytes(bytes);
        stdout.writeln('screenshot → ${file.path}');
        return true;
      },
    );
  } on Object catch (error) {
    // Tests often finish and write PNGs before the VM service tears down;
    // flutter drive then fails on requestData with "Service has disappeared".
    final message = error.toString();
    if (message.contains('Service has disappeared') ||
        message.contains('Failed to fulfill RequestData')) {
      stderr.writeln(
        'integration driver: VM service gone after tests (screenshots may '
        'already be on disk): $error',
      );
      exit(0);
    }
    rethrow;
  }
}
