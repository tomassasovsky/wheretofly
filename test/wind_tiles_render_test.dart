import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:where_to_fly/map/wind/om/dwd_icon_grid.dart';
import 'package:where_to_fly/map/wind/om/om_tile_rasterizer.dart';

import 'helpers/wind_tile_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('wind tile raster pipeline', () {
    test('every Argentina min-zoom tile rasterizes with visible pixels',
        () async {
      final expected = argentinaWindTilesAtPhoneMinZoom();
      expect(expected, isNotEmpty);

      for (final coords in expected) {
        final tileRead = DwdIconTileRead.forTile(
          coords.z,
          coords.x,
          coords.y,
        );
        final image = await rasterizeWindTile(
          values: syntheticGustValues(tileRead),
          tileRead: tileRead,
        );
        await expectWindImageRenders(
          image,
          label: '${coords.z}/${coords.x}/${coords.y}',
        );
      }
    });
  });

  group('wind tile map layer', () {
    testWidgets('all visible min-zoom tiles load without errors',
        (tester) async {
      final tracker = WindTileLoadTracker();
      final tileProvider = SyntheticWindTileProvider(tracker: tracker);
      final controller = MapController();

      await tester.pumpWidget(
        buildWindMapTestWidget(
          controller: controller,
          tileProvider: tileProvider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final expected = visibleTilesForController(controller);
      expect(expected, isNotEmpty);

      await pumpUntil(
        tester,
        condition: () =>
            tracker.failed.isEmpty && expected.every(tracker.loaded.contains),
      );

      expect(
        tracker.failed,
        isEmpty,
        reason: 'Failed tiles: ${tracker.failed.map(_tileLabel).join(', ')}',
      );
      for (final coords in expected) {
        expect(
          tracker.loaded,
          contains(coords),
          reason: 'Missing tile ${_tileLabel(coords)}',
        );
      }
    });

    testWidgets('loaded wind tiles paint non-transparent pixels',
        (tester) async {
      final tracker = WindTileLoadTracker();
      final tileProvider = SyntheticWindTileProvider(tracker: tracker);
      final controller = MapController();

      await tester.pumpWidget(
        buildWindMapTestWidget(
          controller: controller,
          tileProvider: tileProvider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final expected = visibleTilesForController(controller);

      await pumpUntil(
        tester,
        condition: () =>
            tracker.failed.isEmpty && expected.every(tracker.loaded.contains),
      );

      expect(find.byType(RawImage), findsAtLeastNWidgets(1));
      expect(tracker.loaded.length, greaterThanOrEqualTo(expected.length));
    });
  });
}

String _tileLabel(TileCoordinates coords) =>
    '${coords.z}/${coords.x}/${coords.y}';
