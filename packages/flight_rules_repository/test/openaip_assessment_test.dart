import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';
import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/openaip_airspace_parser.dart';
import 'package:zones_api_client/src/zone_permission_ids.dart';

void main() {
  group('OpenAIP flight assessment', () {
    test('uses polygon geometry for horizontal containment', () {
      final zone = OpenAipAirspaceParser.parseRecord(
        properties: {
          '_id': 'eze_ctr',
          'name': 'EZE CTR',
          'type': 4,
          'lowerLimit': {'value': 0, 'unit': 1, 'referenceDatum': 0},
          'upperLimit': {'value': 2500, 'unit': 1, 'referenceDatum': 1},
        },
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [-58.55, -34.82],
              [-58.45, -34.82],
              [-58.45, -34.78],
              [-58.55, -34.78],
              [-58.55, -34.82],
            ],
          ],
        },
      );
      expect(zone, isNotNull);

      final repo = FlightRulesRepository.fromZoneData([zone!]);
      final inside = repo.assess(
        const LatLng(-34.80, -58.50),
        PermissionLevel.recreational,
        FlightModality.vlos,
        zones: repo.zones,
      );
      final outside = repo.assess(
        const LatLng(-34.60, -58.36),
        PermissionLevel.recreational,
        FlightModality.vlos,
        zones: repo.zones,
      );

      expect(inside.zones, hasLength(1));
      expect(inside.verdict, FlightVerdict.notAllowed);
      expect(outside.zones, isEmpty);
      expect(outside.verdict, FlightVerdict.allowed);
    });

    test('applies MSL floor against planned AGL band', () {
      final zone = OpenAipAirspaceParser.parseRecord(
        properties: {
          '_id': 'high_tma',
          'name': 'TMA HIGH FLOOR',
          'type': 7,
          'lowerLimit': {'value': 3000, 'unit': 1, 'referenceDatum': 1},
          'upperLimit': {'value': 4500, 'unit': 1, 'referenceDatum': 1},
        },
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [-58.55, -34.82],
              [-58.45, -34.82],
              [-58.45, -34.78],
              [-58.55, -34.78],
              [-58.55, -34.82],
            ],
          ],
        },
      );
      expect(zone, isNotNull);

      final repo = FlightRulesRepository.fromZoneData([zone!]);
      const point = LatLng(-34.80, -58.50);
      final openCategory = repo.assess(
        point,
        PermissionLevel.registeredPilot,
        FlightModality.evlos,
        zones: repo.zones,
      );

      expect(openCategory.zones, isEmpty);
      expect(openCategory.skippedByAltitude, hasLength(1));
      expect(openCategory.hasMslAltitudeUncertainty, isTrue);
      expect(openCategory.verdict, FlightVerdict.allowed);
    });

    test('blocks recreational pilots in GND-limited CTR', () {
      final zone = OpenAipAirspaceParser.parseRecord(
        properties: {
          '_id': 'atz',
          'name': 'EL PALOMAR ATZ',
          'type': 13,
          'lowerLimit': {'value': 0, 'unit': 1, 'referenceDatum': 0},
          'upperLimit': {'value': 2500, 'unit': 1, 'referenceDatum': 1},
        },
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [-58.55, -34.82],
              [-58.45, -34.82],
              [-58.45, -34.78],
              [-58.55, -34.78],
              [-58.55, -34.82],
            ],
          ],
        },
      );
      expect(zone, isNotNull);

      final repo = FlightRulesRepository.fromZoneData([zone!]);
      const point = LatLng(-34.80, -58.50);
      final recreational = repo.assess(
        point,
        PermissionLevel.recreational,
        FlightModality.vlos,
        zones: repo.zones,
      );
      final commercial = repo.assess(
        point,
        PermissionLevel.authorizedCommercial,
        FlightModality.vlos,
        zones: repo.zones,
      );

      expect(recreational.verdict, FlightVerdict.notAllowed);
      expect(commercial.verdict, FlightVerdict.allowedWithPermission);
      expect(commercial.hasControlledAirspaceZones, isTrue);
    });

    test('prohibited OpenAIP airspace blocks every permission', () {
      final repo = FlightRulesRepository.fromZoneData([
        const ZoneData(
          id: 'openaip_prohibited',
          name: 'SAP 01',
          categoryId: 'prohibited',
          latitude: -34.55,
          longitude: -58.65,
          radiusMeters: 5000,
          allowedPermissionIds: ZonePermissionIds.none,
          details: 'OpenAIP prohibited area',
        ),
      ]);

      final assessment = repo.assess(
        const LatLng(-34.55, -58.65),
        PermissionLevel.specialPermit,
        FlightModality.vlos,
        zones: repo.zones,
      );

      expect(assessment.verdict, FlightVerdict.notAllowed);
      expect(assessment.minimumRequiredPermission, isNull);
    });
  });
}
