import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:where_to_fly/map/view/widgets/config_bar.dart';

import 'helpers/screenshot_bootstrap.dart';
import 'helpers/screenshot_test_support.dart';
import 'helpers/store_screenshot_config.dart';

/// Captures raw simulator screenshots for App Store / Play Store assets.
///
/// Run via tooling/store_assets/capture_and_generate.sh (uses flutter drive).
///
/// All six screenshots are attempted regardless of individual step failures —
/// the test reports which ones were missed at the end rather than aborting
/// mid-run and leaving the compose step with a partial set.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture store screenshots', (tester) async {
    await bootstrapForStoreScreenshots();

    // Tracks screenshots that could not be taken so we can fail informatively
    // at the end instead of cascading from the first error.
    final missed = <String>[];

    // Runs [action] and captures [name]. On failure the error is printed and
    // [name] is added to [missed]; execution continues with the next step.
    Future<void> step(String name, Future<void> Function() action) async {
      try {
        await action();
        await captureStoreScreenshot(binding, tester, name);
        debugPrint('✓ $name');
      } catch (e, s) {
        debugPrint('✗ $name FAILED: $e\n$s');
        missed.add(name);
      }
    }

    // ── 01: zones map ────────────────────────────────────────────────────────
    await pumpFor(tester, const Duration(seconds: 10));

    await step('01-map-zones', () async {
      // Nothing extra needed — the map is already the initial route.
    });

    // ── 02: verdict card ─────────────────────────────────────────────────────
    await step('02-map-verdict', () async {
      await selectMapPoint(tester, StoreScreenshotConfig.verdictPoint);
    });

    // ── 03: config / permission sheet ────────────────────────────────────────
    await step('03-config-sheet', () async {
      final configTap = find.byKey(ConfigBar.tapKey);
      expect(configTap, findsOneWidget, reason: 'ConfigBar tap key not found');
      await tester.tap(configTap);
      await pumpFor(tester, const Duration(seconds: 2));
    });

    // Dismiss the config sheet before moving on.
    await dismissModalBottomSheet(tester);

    // ── 04: search results ───────────────────────────────────────────────────
    await step('04-map-search', () async {
      final searchField = find.byKey(const ValueKey('map_search_field'));
      expect(searchField, findsOneWidget, reason: 'Search field not found');
      await tester.enterText(searchField, 'Córdoba');
      // await pumpFor(tester, const Duration(milliseconds: 500));
      // const query =
      //     StoreScreenshotConfig.localeCode == 'es' ? 'Córdoba' : 'Cordoba';
      // await tester.enterText(searchField, query);
      // // Wait for geocoder results to arrive.
      await pumpFor(tester, const Duration(seconds: 5));
    });

    // Dismiss search so the map is clean for the next shots.
    await dismissSearchFocus(tester);

    // ── 05: resources screen ─────────────────────────────────────────────────
    await step('05-resources', () async {
      await openResourcesScreen(tester);
    });

    // ── 06: wind overlay ─────────────────────────────────────────────────────
    // Wind tiles are network-dependent; tile rendering may not finish — capture
    // whatever is visible. Weather uses [StoreScreenshotWeatherRepository].
    await step('06-map-wind', () async {
      await openMapScreen(tester);
      await clearMapSelection(tester);
      final windFab = find.byKey(const ValueKey('map_wind_overlay_toggle'));
      expect(
        windFab,
        findsOneWidget,
        reason: 'Wind FAB not found — is WIND_MAP_ENABLED=false?',
      );
      await tester.tap(windFab, warnIfMissed: false);
      await tester.pump();
      await pumpFor(tester, const Duration(seconds: 30));
    });

    // ── final check ──────────────────────────────────────────────────────────
    expect(
      missed,
      isEmpty,
      reason: 'The following screenshots failed: ${missed.join(', ')}. '
          'Check the output above for per-step errors.',
    );
  });
}
