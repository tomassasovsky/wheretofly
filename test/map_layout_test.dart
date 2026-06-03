import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/map_layout.dart';

void main() {
  group('MapLayout', () {
    test('overlay insets match monolith constants', () {
      expect(MapLayout.topOverlayInset, 76.0);
      expect(MapLayout.bottomOverlayInset, 108.0);
    });
  });
}
