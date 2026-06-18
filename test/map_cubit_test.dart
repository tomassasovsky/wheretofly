import 'package:bloc_test/bloc_test.dart';
import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';

void main() {
  group('MapCubit', () {
    late FlightRulesRepository repository;
    late SettingsRepository settingsRepository;

    setUp(() async {
      repository = FlightRulesRepository();
      SharedPreferences.setMockInitialValues({});
      settingsRepository = SettingsRepository(
        Storage(await SharedPreferences.getInstance()),
      );
    });

    test('initial state exposes zones, permission and modality', () {
      final cubit = MapCubit(repository);
      expect(cubit.state.permission, PermissionLevel.recreational);
      expect(cubit.state.modality, FlightModality.vlos);
      expect(cubit.state.zones, isNotEmpty);
      expect(cubit.state.altitudeRange.maxMetersAgl, 122);
      addTearDown(cubit.close);
    });

    blocTest<MapCubit, MapState>(
      'selectModality re-evaluates when the pilot may use the modality',
      build: () => MapCubit(repository),
      act: (cubit) => cubit
        ..selectPermission(PermissionLevel.registeredPilot)
        ..checkPoint(const LatLng(-38, -50))
        ..selectModality(FlightModality.evlos),
      verify: (cubit) {
        expect(cubit.state.modality, FlightModality.evlos);
        expect(cubit.state.assessment!.modalityAllowed, isTrue);
        expect(cubit.state.assessment!.verdict, FlightVerdict.allowed);
      },
    );

    blocTest<MapCubit, MapState>(
      'selectModality ignores modalities above held permission',
      build: () => MapCubit(repository),
      seed: () => MapState(
        zones: repository.zones,
      ),
      act: (cubit) => cubit.selectModality(FlightModality.bvlosFpv),
      verify: (cubit) {
        expect(cubit.state.modality, FlightModality.vlos);
      },
    );

    blocTest<MapCubit, MapState>(
      'checkPoint emits an assessment for the tapped point',
      build: () => MapCubit(repository),
      act: (cubit) => cubit.checkPoint(const LatLng(-34.6080, -58.3702)),
      verify: (cubit) {
        expect(cubit.state.assessment, isNotNull);
        expect(cubit.state.assessment!.verdict, FlightVerdict.notAllowed);
      },
    );

    blocTest<MapCubit, MapState>(
      'selectPermission re-evaluates the current selection',
      build: () => MapCubit(repository),
      act: (cubit) => cubit
        ..checkPoint(const LatLng(-34.5592, -58.4156))
        ..selectPermission(PermissionLevel.specialPermit),
      verify: (cubit) {
        expect(
          cubit.state.assessment!.verdict,
          FlightVerdict.allowedWithPermission,
        );
      },
    );

    blocTest<MapCubit, MapState>(
      'clearSelection removes point and assessment',
      build: () => MapCubit(repository),
      act: (cubit) => cubit
        ..checkPoint(const LatLng(-34.6080, -58.3702))
        ..clearSelection(),
      verify: (cubit) {
        expect(cubit.state.selectedPoint, isNull);
        expect(cubit.state.assessment, isNull);
      },
    );

    blocTest<MapCubit, MapState>(
      'checkPoint on empty-zone repository emits uncertain assessment',
      build: () => MapCubit(FlightRulesRepository.fromZoneData([])),
      act: (cubit) => cubit.checkPoint(const LatLng(-34.6080, -58.3702)),
      verify: (cubit) {
        final assessment = cubit.state.assessment!;
        expect(assessment.status, VerdictStatus.uncertain);
        expect(assessment.reasons, contains(VerdictReason.zoneDataUnavailable));
        // Conservative legacy mapping — never a silent false "allowed".
        expect(assessment.verdict, FlightVerdict.notAllowed);
      },
    );

    blocTest<MapCubit, MapState>(
      'updateZones to an empty list yields uncertain for the selected point',
      build: () => MapCubit(repository),
      act: (cubit) => cubit
        ..checkPoint(const LatLng(-38, -50))
        ..updateZones([]),
      verify: (cubit) {
        final assessment = cubit.state.assessment!;
        expect(assessment.status, VerdictStatus.uncertain);
        expect(assessment.reasons, contains(VerdictReason.zoneDataUnavailable));
      },
    );

    blocTest<MapCubit, MapState>(
      'selectAltitudeRange persists and re-evaluates',
      build: () => MapCubit(repository, settingsRepository: settingsRepository),
      act: (cubit) => cubit
        ..checkPoint(const LatLng(-38, -50))
        ..selectAltitudeRange(0, 80),
      verify: (cubit) {
        expect(cubit.state.altitudeRange.maxMetersAgl, 80);
        expect(
          settingsRepository.flightAltitudeRangeAgl.max,
          80,
        );
        expect(cubit.state.assessment, isNotNull);
      },
    );
  });
}
