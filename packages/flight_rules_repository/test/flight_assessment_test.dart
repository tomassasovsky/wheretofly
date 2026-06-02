import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';
import 'package:zones_api_client/src/models/zone_data.dart';

void main() {
  group('FlightAssessment.minimumRequiredPermission', () {
    test('open area + VLOS requires recreational permission', () {
      const assessment = FlightAssessment(
        permission: PermissionLevel.recreational,
        modality: FlightModality.vlos,
        verdict: FlightVerdict.allowed,
        modalityAllowed: true,
        altitudeRange: AltitudeRange.openCategoryDefault,
        zones: [],
      );

      expect(
        assessment.minimumRequiredPermission,
        PermissionLevel.recreational,
      );
    });

    test('open area + BVLOS requires commercial authorization', () {
      const assessment = FlightAssessment(
        permission: PermissionLevel.recreational,
        modality: FlightModality.bvlosFpv,
        verdict: FlightVerdict.notAllowed,
        modalityAllowed: false,
        altitudeRange: AltitudeRange.openCategoryDefault,
        zones: [],
      );

      expect(
        assessment.minimumRequiredPermission,
        PermissionLevel.authorizedCommercial,
      );
    });

    test('controlled airspace requires commercial authorization for VLOS', () {
      final repo = FlightRulesRepository.fromZoneData([
        const ZoneData(
          id: 'ctr',
          name: 'CTR',
          categoryId: 'controlled_airspace',
          latitude: -34.55,
          longitude: -58.65,
          radiusMeters: 5000,
          allowedPermissionIds: {
            'authorized_commercial',
            'special_permit',
          },
          details: 'test',
        ),
      ]);
      final recreational = repo.assess(
        const LatLng(-34.55, -58.65),
        PermissionLevel.recreational,
        FlightModality.vlos,
      );
      final commercial = repo.assess(
        const LatLng(-34.55, -58.65),
        PermissionLevel.authorizedCommercial,
        FlightModality.vlos,
      );

      expect(
        recreational.minimumRequiredPermission,
        PermissionLevel.authorizedCommercial,
      );
      expect(commercial.verdict, FlightVerdict.allowedWithPermission);
    });

    test('prohibited zone has no minimum permission', () {
      final repo = FlightRulesRepository.fromZoneData([
        const ZoneData(
          id: 'prohibited',
          name: 'Prohibited',
          categoryId: 'prohibited',
          latitude: -34.55,
          longitude: -58.65,
          radiusMeters: 5000,
          allowedPermissionIds: {},
          details: 'test',
        ),
      ]);
      final assessment = repo.assess(
        const LatLng(-34.55, -58.65),
        PermissionLevel.specialPermit,
        FlightModality.vlos,
      );

      expect(assessment.minimumRequiredPermission, isNull);
    });
  });
}
