import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
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

    test('markers returns empty set when no point selected', () {
      const state = MapState(zones: [zone]);
      expect(MapZoneOverlayBuilder.markers(state), isEmpty);
    });

    test('markers returns selected point marker', () {
      const point = LatLng(-34.61, -58.36);
      const state = MapState(
        zones: [zone],
        selectedPoint: point,
      );
      final markers = MapZoneOverlayBuilder.markers(state);
      expect(markers, hasLength(1));
      expect(markers.first.position.latitude, point.latitude);
      expect(markers.first.position.longitude, point.longitude);
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

      final circles = MapZoneOverlayBuilder.circles(
        state,
        visibleBounds: gmaps.LatLngBounds(
          southwest: const gmaps.LatLng(-35, -59),
          northeast: const gmaps.LatLng(-34, -58),
        ),
        zoom: 12,
        isDark: false,
      );

      expect(circles, hasLength(1));
      expect(circles.first.circleId.value, zone.id);
    });
  });
}
