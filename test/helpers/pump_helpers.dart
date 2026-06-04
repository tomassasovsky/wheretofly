import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps frames without [WidgetTester.pumpAndSettle], which never finishes
/// while the map screen loads network tiles in widget tests.
Future<void> pumpRouterFrames(
  WidgetTester tester, {
  int frames = 3,
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Clears the element tree so shared [GlobalKey]s (e.g. root navigator) reset.
Future<void> resetWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}
