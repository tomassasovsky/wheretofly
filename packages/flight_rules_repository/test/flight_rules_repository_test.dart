import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';
import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/zone_permission_ids.dart';

void main() {
  group('FlightRulesRepository', () {
    late FlightRulesRepository repository;

    // Far out in the Atlantic — no restricted zones.
    const openSea = LatLng(-38, -50);
    // Plaza de Mayo — prohibited for everyone.
    const plazaDeMayo = LatLng(-34.6080, -58.3702);
    // Aeroparque — controlled airspace.
    const aeroparque = LatLng(-34.5592, -58.4156);
    // Hipólito Vieytes 1025, Barracas — urban BA outside Aeroparque buffer.
    const vieytes1025 = LatLng(-34.6421985, -58.3797108);

    setUp(() => repository = FlightRulesRepository());

    test('maps the data client into domain zones', () {
      expect(repository.zones, isNotEmpty);
      expect(repository.zones.first, isA<FlyZone>());
    });

    test('open area + VLOS is allowed for any permission', () {
      final result = repository.assess(
        openSea,
        PermissionLevel.recreational,
        FlightModality.vlos,
      );
      expect(result.verdict, FlightVerdict.allowed);
      expect(result.zones, isEmpty);
    });

    test('BVLOS/FPV requires authorization even in open area', () {
      final result = repository.assess(
        openSea,
        PermissionLevel.recreational,
        FlightModality.bvlosFpv,
      );
      expect(result.modalityAllowed, isFalse);
      expect(result.verdict, FlightVerdict.notAllowed);
    });

    test('prohibited zone is not allowed even with special permit', () {
      final result = repository.assess(
        plazaDeMayo,
        PermissionLevel.specialPermit,
        FlightModality.vlos,
      );
      expect(result.verdict, FlightVerdict.notAllowed);
      expect(result.blockingZones, isNotEmpty);
    });

    test('mid-altitude zone overlaps climb 0–122 m AGL', () {
      final repo = FlightRulesRepository.fromZoneData([
        const ZoneData(
          id: 'mid_slice',
          name: 'MID ALTITUDE',
          categoryId: 'restricted',
          latitude: -34.55,
          longitude: -58.65,
          radiusMeters: 5000,
          allowedPermissionIds: {'special_permit'},
          details: 'test',
          lowerLimitMetersAgl: 50,
          upperLimitMetersAgl: 80,
        ),
      ]);
      const point = LatLng(-34.55, -58.65);
      final result = repo.assess(
        point,
        PermissionLevel.registeredPilot,
        FlightModality.evlos,
      );
      expect(result.zones, hasLength(1));
      expect(result.verdict, FlightVerdict.notAllowed);
    });

    test('high MSL floor excludes zone at 122 m AGL', () {
      final repo = FlightRulesRepository.fromZoneData([
        const ZoneData(
          id: 'high_tma',
          name: 'TMA HIGH FLOOR',
          categoryId: 'controlled_airspace',
          latitude: -34.55,
          longitude: -58.65,
          radiusMeters: 50000,
          allowedPermissionIds: {'special_permit'},
          details: 'test',
          lowerLimitMetersMsl: 914.4, // 3000 ft MSL
        ),
      ]);
      const point = LatLng(-34.55, -58.65);
      final result = repo.assess(
        point,
        PermissionLevel.registeredPilot,
        FlightModality.evlos,
      );
      expect(result.zones, isEmpty);
      expect(result.skippedByAltitude, hasLength(1));
      expect(result.verdict, FlightVerdict.allowed);
    });

    test('controlled airspace blocks recreational, allows commercial', () {
      expect(
        repository
            .assess(
              aeroparque,
              PermissionLevel.recreational,
              FlightModality.vlos,
            )
            .verdict,
        FlightVerdict.notAllowed,
      );
      expect(
        repository
            .assess(
              aeroparque,
              PermissionLevel.authorizedCommercial,
              FlightModality.vlos,
            )
            .verdict,
        FlightVerdict.allowedWithPermission,
      );
      expect(
        repository
            .assess(
              aeroparque,
              PermissionLevel.specialPermit,
              FlightModality.vlos,
            )
            .verdict,
        FlightVerdict.allowedWithPermission,
      );
    });

    test('commercial VLOS allowed at Hipólito Vieytes 1025, Barracas', () {
      final result = repository.assess(
        vieytes1025,
        PermissionLevel.authorizedCommercial,
        FlightModality.vlos,
      );

      expect(result.verdict, FlightVerdict.allowedWithPermission);
      expect(
        result.minimumRequiredPermission,
        PermissionLevel.authorizedCommercial,
      );
      expect(
        result.zones.any((z) => z.id == 'madhel_AER'),
        isFalse,
        reason: 'Aeroparque buffer should not reach Barracas',
      );
    });

    test('commercial VLOS allowed at Puerto Madero outside Casa Rosada', () {
      const puertoMadero = LatLng(-34.6103764, -58.3622067);
      final result = repository.assess(
        puertoMadero,
        PermissionLevel.authorizedCommercial,
        FlightModality.vlos,
      );

      expect(result.verdict, FlightVerdict.allowedWithPermission);
      expect(
        result.zones.any((z) => z.id == 'prohibited_casa_rosada'),
        isFalse,
        reason: 'Puerto Madero is outside the Casa Rosada security buffer',
      );
      expect(
        result.blockingZones,
        isEmpty,
      );
    });

    test('commercial VLOS allowed inside SAR 01 Capital Federal', () {
      final repo = FlightRulesRepository.fromZoneData([
        const ZoneData(
          id: 'openaip_sar01',
          name: 'SAR 01 Capital Federal',
          categoryId: 'restricted',
          latitude: -34.6103764,
          longitude: -58.3622067,
          radiusMeters: 20000,
          allowedPermissionIds: ZonePermissionIds.controlledAirspace,
          details: 'OpenAIP restricted area',
        ),
      ]);
      final result = repo.assess(
        const LatLng(-34.6103764, -58.3622067),
        PermissionLevel.authorizedCommercial,
        FlightModality.vlos,
      );

      expect(result.verdict, FlightVerdict.allowedWithPermission);
      expect(result.blockingZones, isEmpty);
    });
  });
}
