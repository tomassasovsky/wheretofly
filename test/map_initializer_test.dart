import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/map_config.dart';
import 'package:where_to_fly/map/map_initializer.dart';

void main() {
  test('argentina center and geographic bounds', () {
    expect(MapInitializer.argentinaCenter.latitude, -38.4161);
    expect(MapInitializer.argentinaCenter.longitude, -63.6167);
    final bounds = MapInitializer.argentinaBounds;
    expect(bounds.south, lessThan(-50));
    expect(bounds.north, greaterThan(-20));
    expect(bounds.west, lessThan(-70));
    expect(bounds.east, greaterThan(-50));
  });

  testWidgets('mapBrightnessFor honors ThemeMode.dark', (tester) async {
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(
      MapInitializer.mapBrightnessFor(context, ThemeMode.dark),
      Brightness.dark,
    );
  });

  test('mapTileTemplateFor uses CARTO raster defaults', () {
    expect(
      MapInitializer.mapTileTemplateFor(Brightness.light),
      MapConfig.cartoVoyagerTileUrl,
    );
    expect(
      MapInitializer.mapTileTemplateFor(Brightness.dark),
      MapConfig.cartoDarkMatterTileUrl,
    );
  });
}
