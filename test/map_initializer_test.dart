import 'package:argentina_bounds/argentina_bounds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/map_config.dart';
import 'package:where_to_fly/map/map_initializer.dart';

void main() {
  test('argentina center and geographic bounds', () {
    expect(MapInitializer.argentinaCenter.latitude, -38.4161);
    expect(MapInitializer.argentinaCenter.longitude, -63.6167);
    final extent = ArgentinaBounds.geographicExtent;
    final bounds = MapInitializer.argentinaBounds;
    expect(bounds.south, closeTo(extent.minLat, 0.01));
    expect(bounds.north, closeTo(extent.maxLat, 0.01));
    expect(bounds.west, closeTo(extent.minLon, 0.01));
    expect(bounds.east, closeTo(extent.maxLon, 0.01));
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

  test('tileUrlTemplateFor uses CARTO raster defaults', () {
    expect(
      MapConfig.tileUrlTemplateFor(Brightness.light),
      MapConfig.cartoVoyagerTileUrl,
    );
    expect(
      MapConfig.tileUrlTemplateFor(Brightness.dark),
      MapConfig.cartoDarkMatterTileUrl,
    );
  });
}
