import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/map_visible_bounds.dart';
import 'package:where_to_fly/map/map_zone_display.dart';

void main() {
  group('MapZoneDisplay', () {
    const smallControlled = FlyZone(
      id: 'ctr',
      name: 'CTR',
      category: ZoneCategory.controlledAirspace,
      center: LatLng(-34.61, -58.36),
      radiusMeters: 1500,
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
      const bounds = MapVisibleBounds(
        southWest: LatLng(-34.7, -58.5),
        northEast: LatLng(-34.55, -58.3),
      );
      final visible = MapZoneDisplay.visibleZones(
        zones: [smallControlled],
        bounds: bounds,
        zoom: 14,
      );
      expect(visible, hasLength(1));

      const outsideBounds = MapVisibleBounds(
        southWest: LatLng(-40, -65),
        northEast: LatLng(-39, -64),
      );
      final outside = MapZoneDisplay.visibleZones(
        zones: [smallControlled],
        bounds: outsideBounds,
        zoom: 14,
      );
      expect(outside, isEmpty);
    });

    test('hides small controlled zones below urban zoom', () {
      final visible = MapZoneDisplay.visibleZones(
        zones: [smallControlled],
        bounds: null,
        zoom: 10,
      );
      expect(visible, isEmpty);
    });

    const madhelAerodrome = FlyZone(
      id: 'madhel_ACM',
      name: 'La Cura Malal',
      category: ZoneCategory.restricted,
      center: LatLng(-34.08, -60.14),
      radiusMeters: 2500,
      permissionsThatAllowFlight: {PermissionLevel.authorizedCommercial},
      details: 'test',
    );

    test('keeps MADHEL aerodromes when zoomed out', () {
      final visible = MapZoneDisplay.visibleZones(
        zones: [madhelAerodrome],
        bounds: null,
        zoom: 8,
      );
      expect(visible, hasLength(1));
    });

    test('fills MADHEL aerodromes at wide zoom for visibility', () {
      expect(
        MapZoneDisplay.shouldFill(
          madhelAerodrome,
          highlighted: false,
          zoom: 8,
        ),
        isTrue,
      );
      expect(
        MapZoneDisplay.fillAlpha(
          madhelAerodrome,
          isDark: false,
          highlighted: false,
          zoom: 8,
        ),
        greaterThan(0),
      );
    });

    test('prioritizes MADHEL over generic controlled when culling', () {
      final zones = List.generate(
        350,
        (i) => FlyZone(
          id: 'openaip_zone_$i',
          name: 'Zone $i',
          category: ZoneCategory.controlledAirspace,
          center: LatLng(-34.6 + i * 0.001, -58.4),
          radiusMeters: 3000,
          permissionsThatAllowFlight: const {
            PermissionLevel.authorizedCommercial,
          },
          details: 'test',
        ),
      )..add(madhelAerodrome);

      final visible = MapZoneDisplay.visibleZones(
        zones: zones,
        bounds: null,
        zoom: 14,
      );

      expect(visible.any((z) => z.id == 'madhel_ACM'), isTrue);
      expect(visible, hasLength(300));
    });
  });
}
