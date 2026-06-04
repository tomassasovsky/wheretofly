import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/app/router/root_navigator_key.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/cubit/map_search_cubit.dart';

/// Pumps frames for [duration] without `pumpAndSettle`
/// (map tiles never settle).
Future<void> pumpFor(
  WidgetTester tester,
  Duration duration, {
  Duration step = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
  }
}

bool _androidSurfaceConverted = false;

/// [MapCubit] / [MapSearchCubit] live under [MapPage], not [rootNavigatorKey].
BuildContext _mapBlocContext(WidgetTester tester) {
  final finder = find.byKey(const ValueKey('map_search_field'));
  expect(
    finder,
    findsOneWidget,
    reason: 'Map screen not visible — navigate to /map first',
  );
  return tester.element(finder);
}

/// Host-side screenshot capture (iOS simulator + Android emulator).
Future<void> captureStoreScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  if (Platform.isAndroid && !_androidSurfaceConverted) {
    await binding.convertFlutterSurfaceToImage();
    _androidSurfaceConverted = true;
  }
  if (Platform.isAndroid) {
    await tester.pump();
  }
  await binding.takeScreenshot(name);
}

Future<void> openResourcesScreen(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      fail('rootNavigatorKey has no context');
    }
    await pumpFor(tester, const Duration(seconds: 2));
    if (context.mounted) {
      const ResourcesRoute(highlight: 'recreational').replace(context);
    }
  });
  await pumpFor(tester, const Duration(seconds: 2));
}

/// Selects [point] on the map (zone assessment + weather fixture in capture
/// mode).
Future<void> selectMapPoint(
  WidgetTester tester,
  LatLng point, {
  Duration settle = const Duration(seconds: 4),
}) async {
  final context = _mapBlocContext(tester);
  await tester.runAsync(() async {
    if (!context.mounted) return;
    final searchCubit = context.read<MapSearchCubit>()..dismissResults();
    context.read<MapCubit>().checkPoint(point);
    await searchCubit.resolveAddressForPoint(point);
  });
  await pumpFor(tester, settle);
}

/// Clears the verdict card so wind / zones shots are not duplicated from #2.
Future<void> clearMapSelection(WidgetTester tester) async {
  final context = _mapBlocContext(tester);
  await tester.runAsync(() async {
    if (context.mounted) {
      context.read<MapCubit>().clearSelection();
    }
  });
  await pumpFor(tester, const Duration(seconds: 1));
}

Future<void> openMapScreen(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      fail('rootNavigatorKey has no context');
    }
    if (context.mounted) {
      const MapTabRoute().go(context);
    }
  });
  await pumpFor(tester, const Duration(seconds: 2));
  expect(
    find.byKey(const ValueKey('map_search_field')),
    findsOneWidget,
    reason: 'Map tab did not become visible after navigation',
  );
}

Future<void> popTopRoute(WidgetTester tester) async {
  final back = find.byType(BackButton);
  if (back.evaluate().isNotEmpty) {
    await tester.tap(back);
    return;
  }
  final arrow = find.byIcon(Icons.arrow_back);
  if (arrow.evaluate().isNotEmpty) {
    await tester.tap(arrow);
  }
}

Future<void> dismissModalBottomSheet(WidgetTester tester) async {
  if (find.byType(ModalBarrier).evaluate().isEmpty) return;

  // Tap near the top of the screen — always above any bottom sheet regardless
  // of device size. tester.tap(barrier) hits the widget's center, which lands
  // inside the sheet on large tablets and silently fails (warnIfMissed: false).
  final size = tester.binding.renderViews.first.size;
  await tester.tapAt(Offset(size.width / 2, size.height * 0.08));
  await pumpFor(tester, const Duration(milliseconds: 500));

  // Fallback: pop programmatically if the barrier is still present.
  if (find.byType(ModalBarrier).evaluate().isNotEmpty) {
    await tester.runAsync(() async {
      final context = rootNavigatorKey.currentContext;
      if (context != null && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
    await pumpFor(tester, const Duration(milliseconds: 500));
  }
}

Future<void> dismissSearchFocus(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await pumpFor(tester, const Duration(milliseconds: 300));
  final size = tester.binding.renderViews.first.size;
  await tester.tapAt(Offset(size.width / 2, size.height * 0.08));
  await pumpFor(tester, const Duration(milliseconds: 500));
}
