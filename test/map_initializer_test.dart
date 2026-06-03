import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/map_initializer.dart';

void main() {
  test('initialCamera uses Argentina center and zoom 4.5', () {
    expect(MapInitializer.argentinaCenter.latitude, -38.4161);
    expect(MapInitializer.argentinaCenter.longitude, -63.6167);
    expect(MapInitializer.initialZoom, 4.5);
    expect(
      MapInitializer.initialCamera.target,
      MapInitializer.argentinaCenter,
    );
    expect(MapInitializer.initialCamera.zoom, MapInitializer.initialZoom);
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

  test('mapColorSchemeFor is null off-web', () {
    expect(MapInitializer.mapColorSchemeFor(Brightness.dark), isNull);
  });
}
