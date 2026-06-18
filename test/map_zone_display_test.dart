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

    const madhelAerodrome = FlyZone(
      id: 'madhel_ACM',
      name: 'La Cura Malal',
      category: ZoneCategory.restricted,
      center: LatLng(-34.08, -60.14),
      radiusMeters: 2500,
      permissionsThatAllowFlight: {PermissionLevel.authorizedCommercial},
      details: 'test',
      source: ZoneSource.madhel,
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

    test('draws zones of any source (no source-based debug filter)', () {
      final visible = MapZoneDisplay.visibleZones(
        zones: [smallControlled, madhelAerodrome],
        bounds: null,
        zoom: 14,
      );
      expect(visible.map((z) => z.id), containsAll(['ctr', 'madhel_ACM']));
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

    group('altitude relevance filter', () {
      const highFloorAgl = FlyZone(
        id: 'airway',
        name: 'High airway',
        category: ZoneCategory.controlledAirspace,
        center: LatLng(-34.61, -58.36),
        radiusMeters: 5000,
        permissionsThatAllowFlight: {PermissionLevel.authorizedCommercial},
        details: 'test',
        lowerLimitMetersAgl: 2000,
      );

      const fl045Msl = FlyZone(
        id: 'fl045',
        name: 'FL045 floor',
        category: ZoneCategory.controlledAirspace,
        center: LatLng(-34.61, -58.36),
        radiusMeters: 5000,
        permissionsThatAllowFlight: {PermissionLevel.authorizedCommercial},
        details: 'test',
        lowerLimitMetersMsl: 1372,
      );

      const lowFloor = FlyZone(
        id: 'low',
        name: 'Low floor',
        category: ZoneCategory.controlledAirspace,
        center: LatLng(-34.61, -58.36),
        radiusMeters: 5000,
        permissionsThatAllowFlight: {PermissionLevel.authorizedCommercial},
        details: 'test',
        lowerLimitMetersAgl: 100,
      );

      List<FlyZone> visible(
        List<FlyZone> zones, {
        Set<String> highlightIds = const {},
      }) =>
          MapZoneDisplay.visibleZones(
            zones: zones,
            bounds: null,
            zoom: 14,
            highlightIds: highlightIds,
          );

      test('hides a zone whose known AGL floor is above the ceiling', () {
        expect(visible([highFloorAgl]), isEmpty);
      });

      test('hides an FL045-floored (MSL) zone at sea level', () {
        expect(visible([fl045Msl]), isEmpty);
      });

      test('shows a zone with unknown vertical limits', () {
        expect(visible([smallControlled]).map((z) => z.id), contains('ctr'));
      });

      test('shows a zone floored below the ceiling', () {
        expect(visible([lowFloor]).map((z) => z.id), contains('low'));
      });

      test('shows a high-floor zone when it is highlighted', () {
        expect(
          visible([highFloorAgl], highlightIds: {'airway'}).map((z) => z.id),
          contains('airway'),
        );
      });
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
      source: ZoneSource.openaip,
    );

    test('keeps every OpenAIP polygon when culling circles', () {
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
          source: ZoneSource.madhel,
        ),
      )..add(openAipPolygon);

      final visible = MapZoneDisplay.visibleZones(
        zones: zones,
        bounds: null,
        zoom: 14,
      );

      // Polygon is exempt from the circle cap; circles are capped to maxCircles.
      expect(visible.first, openAipPolygon);
      expect(visible, hasLength(MapZoneDisplay.maxCircles + 1));
    });

    test('caps circles but keeps every OpenAIP polygon', () {
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
          source: ZoneSource.openaip,
        ),
      )..addAll([openAipPolygon, madhelAerodrome]);

      final visible = MapZoneDisplay.visibleZones(
        zones: zones,
        bounds: null,
        zoom: 14,
      );

      expect(visible.any((z) => z.id == 'openaip_eze_ctr'), isTrue);
      expect(visible, hasLength(MapZoneDisplay.maxCircles + 1));
    });
  });
}
