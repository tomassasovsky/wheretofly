import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/map_config.dart';
import 'package:where_to_fly/map/map_initializer.dart';
import 'package:where_to_fly/map/map_theme.dart';

void main() {
  test('argentina center and initial zoom', () {
    expect(MapInitializer.argentinaCenter.latitude, -38.4161);
    expect(MapInitializer.argentinaCenter.longitude, -63.6167);
    expect(MapInitializer.initialZoom, 4.5);
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

  test('mapStyleFor uses CARTO basemap defaults', () {
    expect(
      MapInitializer.mapStyleFor(Brightness.light),
      MapTheme.lightStyleUrl,
    );
    expect(
      MapInitializer.mapStyleFor(Brightness.dark),
      MapTheme.darkStyleUrl,
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
