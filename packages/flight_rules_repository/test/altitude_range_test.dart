import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:test/test.dart';

void main() {
  group('AltitudeRange', () {
    test('openCategoryDefault uses 122 m ceiling', () {
      expect(
        AltitudeRange.openCategoryDefault.maxMetersAgl,
        AltitudeRange.defaultMaxMetersAgl,
      );
      expect(AltitudeRange.defaultMaxMetersAgl, 122);
    });

    test('clampedFor recreational caps at open category max', () {
      const range = AltitudeRange(minMetersAgl: 0, maxMetersAgl: 400);
      final clamped = range.clampedFor(PermissionLevel.recreational);
      expect(clamped.maxMetersAgl, 122);
    });

    test('clampedFor special permit allows planning ceiling', () {
      const range = AltitudeRange(minMetersAgl: 0, maxMetersAgl: 400);
      final clamped = range.clampedFor(PermissionLevel.specialPermit);
      expect(clamped.maxMetersAgl, 400);
    });
  });
}
