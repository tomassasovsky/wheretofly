import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:where_to_fly/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture zones and wind map screenshots', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 8));

    await binding.takeScreenshot('01-map-zones');

    final windFab = find.byKey(const ValueKey('map_wind_overlay_toggle'));
    if (windFab.evaluate().isEmpty) {
      fail('Wind overlay FAB not found — is WIND_MAP_ENABLED=false?');
    }
    await tester.tap(windFab);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 25));

    await binding.takeScreenshot('02-map-wind');
  });
}
