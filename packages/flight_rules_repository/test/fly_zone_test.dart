import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';

void main() {
  group('FlyZone.constrainsAltitudeBelow', () {
    FlyZone zone({
      double? lowerAgl,
      double? lowerMsl,
    }) =>
        FlyZone(
          id: 'z',
          name: 'Zone',
          category: ZoneCategory.controlledAirspace,
          center: const LatLng(-34.6, -58.4),
          radiusMeters: 5000,
          permissionsThatAllowFlight: const {},
          details: '',
          lowerLimitMetersAgl: lowerAgl,
          lowerLimitMetersMsl: lowerMsl,
        );

    test('true when the zone has no vertical limits (unknown is not high)', () {
      expect(zone().constrainsAltitudeBelow(122), isTrue);
    });

    test('false when the AGL floor is above the ceiling', () {
      expect(zone(lowerAgl: 2000).constrainsAltitudeBelow(500), isFalse);
    });

    test('true when the AGL floor is below the ceiling', () {
      expect(zone(lowerAgl: 100).constrainsAltitudeBelow(500), isTrue);
    });

    test('false for an FL045 MSL floor at sea level', () {
      expect(zone(lowerMsl: 1372).constrainsAltitudeBelow(500), isFalse);
    });

    test('true for an MSL floor once ground elevation is accounted for', () {
      // Floor 1372 m MSL over 1300 m terrain is only 72 m AGL.
      expect(
        zone(lowerMsl: 1372).constrainsAltitudeBelow(
          500,
          groundElevationMslMeters: 1300,
        ),
        isTrue,
      );
    });
  });

  group('FlyZone.contains', () {
    test('falls back to circle when no boundary', () {
      const zone = FlyZone(
        id: 'c',
        name: 'Circle',
        category: ZoneCategory.controlledAirspace,
        center: LatLng(-34.6, -58.4),
        radiusMeters: 1000,
        permissionsThatAllowFlight: {},
        details: '',
      );
      expect(zone.contains(const LatLng(-34.6, -58.4)), isTrue);
      // ~3 km north — outside the 1 km radius.
      expect(zone.contains(const LatLng(-34.573, -58.4)), isFalse);
    });

    test('uses point-in-polygon when boundary is present', () {
      // An L-shaped (concave) ring: a circle would wrongly include the notch.
      const ring = [
        LatLng(0, 0),
        LatLng(0, 4),
        LatLng(2, 4),
        LatLng(2, 2),
        LatLng(4, 2),
        LatLng(4, 0),
      ];
      const zone = FlyZone(
        id: 'l',
        name: 'L',
        category: ZoneCategory.restricted,
        // Bounding centre/radius would cover the notch; boundary must win.
        center: LatLng(2, 2),
        radiusMeters: 1000000,
        permissionsThatAllowFlight: {},
        details: '',
        boundary: ring,
      );

      // Inside the corner of the L (x=1, y=1).
      expect(zone.contains(const LatLng(1, 1)), isTrue);
      // Inside the tall left arm (x=1, y=3).
      expect(zone.contains(const LatLng(3, 1)), isTrue);
      // In the concave notch (x=3, y=3) — outside the polygon but inside the
      // bounding circle, which is exactly the case a circle gets wrong.
      expect(zone.contains(const LatLng(3, 3)), isFalse);
      // Well outside.
      expect(zone.contains(const LatLng(5, 5)), isFalse);
    });
  });
}
