import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host-side driver: writes integration_test screenshots to 
/// `STORE_SCREENSHOT_DIR` (defaults to `<project>/docs/screenshots`).
Future<void> main() async {
  final root =
      Platform.environment['STORE_SCREENSHOT_ROOT'] ?? Directory.current.path;
  final outDir =
      Platform.environment['STORE_SCREENSHOT_DIR'] ?? '$root/docs/screenshots';

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes,
        [Map<String, Object?>? args,]) async {
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
}
