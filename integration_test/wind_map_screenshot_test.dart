import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/screenshot_bootstrap.dart';
import 'helpers/screenshot_test_support.dart';

/// Legacy two-shot capture: zones map + wind overlay.
/// Prefer store_screenshot_test.dart for full store assets.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture zones and wind map screenshots', (tester) async {
    await bootstrapForStoreScreenshots();
    // pumpAndSettle is intentionally avoided — map tiles never settle.
    await pumpFor(tester, const Duration(seconds: 12));
    await captureStoreScreenshot(binding, tester, '01-map-zones');

    final windFab = find.byKey(const ValueKey('map_wind_overlay_toggle'));
    expect(
      windFab,
      findsOneWidget,
      reason: 'Wind overlay FAB not found — is WIND_MAP_ENABLED=false?',
    );
    await tester.tap(windFab);
    await tester.pump();
    await pumpFor(tester, const Duration(seconds: 30));
    await captureStoreScreenshot(binding, tester, '02-map-wind');
  });
}
