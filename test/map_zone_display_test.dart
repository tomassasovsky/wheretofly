import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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

    test('hides non-OpenAIP zones while openAipOnly is enabled', () {
      final visible = MapZoneDisplay.visibleZones(
        zones: [smallControlled],
        bounds: null,
        zoom: 14,
        highlightIds: {'ctr'},
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

    test('hides MADHEL aerodromes while openAipOnly is enabled', () {
      final visible = MapZoneDisplay.visibleZones(
        zones: [madhelAerodrome],
        bounds: null,
        zoom: 8,
      );
      expect(visible, isEmpty);
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

    const openAipPolygon = FlyZone(
      id: 'openaip_eze_ctr',
      name: 'EZE CTR',
      category: ZoneCategory.controlledAirspace,
      center: LatLng(-34.82, -58.5),
      radiusMeters: 15000,
      boundary: [
        LatLng(-34.82, -58.55),
        LatLng(-34.78, -58.55),
        LatLng(-34.78, -58.45),
        LatLng(-34.82, -58.45),
      ],
      permissionsThatAllowFlight: {PermissionLevel.authorizedCommercial},
      details: 'test',
    );

    test('keeps all OpenAIP polygon zones when culling circles', () {
      final zones = List.generate(
        350,
        (i) => FlyZone(
          id: 'madhel_zone_$i',
          name: 'Zone $i',
          category: ZoneCategory.restricted,
          center: LatLng(-34.6 + i * 0.001, -58.4),
          radiusMeters: 3000,
          permissionsThatAllowFlight: const {
            PermissionLevel.authorizedCommercial,
          },
          details: 'test',
        ),
      )..add(openAipPolygon);

      final visible = MapZoneDisplay.visibleZones(
        zones: zones,
        bounds: null,
        zoom: 14,
      );

      expect(visible, [openAipPolygon]);
    });

    test('caps OpenAIP circles but keeps every OpenAIP polygon', () {
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
      )..addAll([openAipPolygon, madhelAerodrome]);

      final visible = MapZoneDisplay.visibleZones(
        zones: zones,
        bounds: null,
        zoom: 14,
      );

      expect(visible.any((z) => z.id == 'openaip_eze_ctr'), isTrue);
      expect(visible.any((z) => z.id == 'madhel_ACM'), isFalse);
      expect(visible, hasLength(301));
    });
  });
}
