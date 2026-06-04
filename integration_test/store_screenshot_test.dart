import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:where_to_fly/main.dart' as app;
import 'package:where_to_fly/map/store_screenshot_config.dart';
import 'package:where_to_fly/map/view/widgets/config_bar.dart';

import 'helpers/screenshot_test_support.dart';

/// Captures raw simulator screenshots for App Store / Play Store assets.
///
/// Run via [tooling/store_assets/capture_and_generate.sh] (uses flutter drive).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture store screenshots', (tester) async {
    app.main();

    await pumpFor(tester, const Duration(seconds: 10));
    await binding.takeScreenshot('01-map-zones');

    await pumpFor(tester, const Duration(seconds: 3));
    await binding.takeScreenshot('02-map-verdict');

    await tester.tap(find.byKey(ConfigBar.tapKey));
    await pumpFor(tester, const Duration(seconds: 2));
    await binding.takeScreenshot('03-config-sheet');

    await tester.tapAt(
      Offset(tester.binding.renderViews.first.size.width / 2, 40),
    );
    await pumpFor(tester, const Duration(seconds: 1));

    final searchField = find.byKey(const ValueKey('map_search_field'));
    await tester.tap(searchField);
    const searchQuery =
        StoreScreenshotConfig.localeCode == 'es' ? 'Córdoba' : 'Cordoba';
    await tester.enterText(searchField, searchQuery);
    await pumpFor(tester, const Duration(seconds: 4));
    await binding.takeScreenshot('04-map-search');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpFor(tester, const Duration(milliseconds: 500));

    await tester.tap(find.byKey(ConfigBar.tapKey));
    await pumpFor(tester, const Duration(seconds: 2));

    final resourcesLink = find.byKey(const ValueKey('map_resources_link'));
    await tester.scrollUntilVisible(
      resourcesLink,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(resourcesLink);
    await pumpFor(tester, const Duration(seconds: 2));
    await binding.takeScreenshot('05-resources');

    await tester.tap(find.byType(BackButton).first);
    await pumpFor(tester, const Duration(seconds: 1));
    await tester.tapAt(
      Offset(tester.binding.renderViews.first.size.width / 2, 40),
    );
    await pumpFor(tester, const Duration(seconds: 1));

    // Wind screenshot: capture script clears search when the overlay is
    // enabled.
    final windFab = find.byKey(const ValueKey('map_wind_overlay_toggle'));
    if (windFab.evaluate().isEmpty) {
      fail('Wind overlay FAB not found — is WIND_MAP_ENABLED=false?');
    }
    await tester.tap(windFab);
    await tester.pump();
    await pumpFor(tester, const Duration(seconds: 25));
    await binding.takeScreenshot('06-map-wind');
  });
}
