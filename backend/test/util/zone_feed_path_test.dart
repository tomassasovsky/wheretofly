import 'dart:io';

import 'package:backend/util/zone_feed_path.dart';
import 'package:test/test.dart';

void main() {
  group('validateZoneFeedPath', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('zone_feed_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('accepts a readable GeoJSON file', () {
      final file = File('${tempDir.path}/zones.geojson');
      file.writeAsStringSync('{"type":"FeatureCollection","features":[]}');

      expect(() => validateZoneFeedPath(file.path), returnsNormally);
    });

    test('throws when path is a directory (Docker bind-mount footgun)', () {
      final dir = Directory('${tempDir.path}/zones.geojson');
      dir.createSync();

      expect(
        () => validateZoneFeedPath(dir.path),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('directory'), contains('must be a file')),
          ),
        ),
      );
    });

    test('throws when file is missing', () {
      expect(
        () => validateZoneFeedPath('${tempDir.path}/missing.geojson'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not found'),
          ),
        ),
      );
    });
  });
}
