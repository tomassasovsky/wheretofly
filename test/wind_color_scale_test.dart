import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/wind/om/wind_color_scale.dart';

void main() {
  test('colorFor interpolates between breakpoints', () {
    final low = WindColorScale.colorFor(5);
    final mid = WindColorScale.colorFor(5.5);
    final high = WindColorScale.colorFor(6);

    expect(mid, isNot(equals(low)));
    expect(mid, isNot(equals(high)));
    expect(mid.g, greaterThan(low.g));
    expect(mid.g, lessThan(high.g));
  });
}
