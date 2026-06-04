import 'package:flutter_test/flutter_test.dart';

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
