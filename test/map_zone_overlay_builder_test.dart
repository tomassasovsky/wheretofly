import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/map_zone_overlay_builder.dart';

void main() {
  group('MapZoneOverlayBuilder', () {
    const zone = FlyZone(
      id: 'prohibited-1',
      name: 'Restricted',
      category: ZoneCategory.prohibited,
      center: LatLng(-34.61, -58.36),
      radiusMeters: 5000,
      permissionsThatAllowFlight: {},
      details: 'test',
    );

    test('selectedPoint is null when no point selected', () {
      const state = MapState(zones: [zone]);
      expect(MapZoneOverlayBuilder.selectedPoint(state), isNull);
    });

    test('selectedPoint returns tap location', () {
      const point = LatLng(-34.61, -58.36);
      const state = MapState(
        zones: [zone],
        selectedPoint: point,
      );
      expect(MapZoneOverlayBuilder.selectedPoint(state), point);
    });

    test('circles includes highlighted assessment zones', () {
      const assessment = FlightAssessment(
        permission: PermissionLevel.recreational,
        modality: FlightModality.vlos,
        verdict: FlightVerdict.notAllowed,
        modalityAllowed: true,
        altitudeRange: AltitudeRange.openCategoryDefault,
        zones: [zone],
      );
      final state = MapState(
        zones: const [zone],
        assessment: assessment,
        selectedPoint: zone.center,
      );

      const bounds = MapVisibleBounds(
        southWest: LatLng(-35, -59),
        northEast: LatLng(-34, -58),
      );
      final circles = MapZoneOverlayBuilder.circles(
        state,
        visibleBounds: bounds,
        zoom: 12,
        isDark: false,
      );

      expect(circles, hasLength(1));
      expect(circles.first.id, zone.id);
      expect(circles.first.radiusMeters, zone.radiusMeters);
    });
  });
}
