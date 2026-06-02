import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/map_zone_display.dart';

void main() {
  group('MapZoneDisplay', () {
    const smallControlled = FlyZone(
      id: 'ctr',
      name: 'CTR',
      category: ZoneCategory.controlledAirspace,
      center: LatLng(-34.61, -58.36),
      radiusMeters: 2000,
      permissionsThatAllowFlight: {PermissionLevel.authorizedCommercial},
      details: 'test',
    );

    test('uses stroke-only styling for controlled airspace by default', () {
      expect(
        MapZoneDisplay.shouldFill(smallControlled, highlighted: false),
        isFalse,
      );
      expect(
        MapZoneDisplay.fillAlpha(
          smallControlled,
          isDark: false,
          highlighted: false,
        ),
        0,
      );
    });

    test('filters to high-severity zones when zoomed out', () {
      final visible = MapZoneDisplay.visibleZones(
        zones: [smallControlled],
        bounds: null,
        zoom: 8,
      );
      expect(visible, isEmpty);
    });

    test('keeps highlighted zones when zoomed out', () {
      final visible = MapZoneDisplay.visibleZones(
        zones: [smallControlled],
        bounds: null,
        zoom: 8,
        highlightIds: {'ctr'},
      );
      expect(visible, hasLength(1));
    });

    test('filters zones outside visible bounds', () {
      final visible = MapZoneDisplay.visibleZones(
        zones: [smallControlled],
        bounds: gmaps.LatLngBounds(
          southwest: const gmaps.LatLng(-34.7, -58.5),
          northeast: const gmaps.LatLng(-34.55, -58.3),
        ),
        zoom: 14,
      );
      expect(visible, hasLength(1));

      final outside = MapZoneDisplay.visibleZones(
        zones: [smallControlled],
        bounds: gmaps.LatLngBounds(
          southwest: const gmaps.LatLng(-40, -65),
          northeast: const gmaps.LatLng(-39, -64),
        ),
        zoom: 14,
      );
      expect(outside, isEmpty);
    });

    test('hides small controlled zones at medium zoom', () {
      final visible = MapZoneDisplay.visibleZones(
        zones: [smallControlled],
        bounds: null,
        zoom: 13,
      );
      expect(visible, isEmpty);
    });
  });
}
