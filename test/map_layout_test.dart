import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/map_layout.dart';

void main() {
  group('MapLayout', () {
    test('overlay insets match layout constants', () {
      expect(MapLayout.topOverlayInset, 76.0);
    });

    testWidgets('zone detail clears config bar including safe area', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
          child: SizedBox(),
        ),
      );
      final context = tester.element(find.byType(SizedBox));
      expect(MapLayout.configBarStackHeight(context), 34 + 12 + 56);
      expect(MapLayout.zoneDetailBottom(context), 34 + 12 + 56 + 12);
    });
  });
}
