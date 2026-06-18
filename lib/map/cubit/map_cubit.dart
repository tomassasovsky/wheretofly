import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:settings_repository/settings_repository.dart';

part 'map_state.dart';

/// Business logic for the map screen: holds the selected permission level and
/// flight modality, the zones to render, and the assessment for the tapped
/// point.
class MapCubit extends Cubit<MapState> {
  MapCubit(this._repository, {SettingsRepository? settingsRepository})
      : _settings = settingsRepository,
        super(
          MapState(
            zones: _repository.zones,
            permission:
                PermissionLevel.fromId(settingsRepository?.permissionId),
            modality: FlightModality.fromId(settingsRepository?.modalityId),
            altitudeRange: _initialAltitudeRange(settingsRepository),
          ),
        );

  final FlightRulesRepository _repository;
  final SettingsRepository? _settings;

  static AltitudeRange _initialAltitudeRange(SettingsRepository? settings) {
    final permission = PermissionLevel.fromId(settings?.permissionId);
    if (settings == null) {
      return AltitudeRange.openCategoryDefault.clampedFor(permission);
    }
    final stored = settings.flightAltitudeRangeAgl;
    return AltitudeRange(
      minMetersAgl: stored.min,
      maxMetersAgl: stored.max,
    ).clampedFor(permission);
  }

  /// Change the permission level the pilot holds and re-evaluate.
  void selectPermission(PermissionLevel permission) {
    unawaited(_settings?.setPermissionId(permission.id));
    final range = state.altitudeRange.clampedFor(permission);
    _persistAltitude(range);
    emit(
      _reassessed(
        state.copyWith(permission: permission, altitudeRange: range),
      ),
    );
  }

  /// Change the flight modality and re-evaluate.
  void selectModality(FlightModality modality) {
    if (state.permission.rank < modality.minimumPermission.rank) return;
    unawaited(_settings?.setModalityId(modality.id));
    emit(_reassessed(state.copyWith(modality: modality)));
  }

  /// Change the planned altitude band (m AGL) and re-evaluate.
  void selectAltitudeRange(double minMetersAgl, double maxMetersAgl) {
    final range = AltitudeRange(
      minMetersAgl: minMetersAgl,
      maxMetersAgl: maxMetersAgl,
    ).clampedFor(state.permission);
    _persistAltitude(range);
    emit(_reassessed(state.copyWith(altitudeRange: range)));
  }

  /// Evaluate the tapped [point] under the current permission and modality.
  void checkPoint(LatLng point) {
    emit(
      state.copyWith(
        selectedPoint: point,
        assessment: _repository.assess(
          point,
          state.permission,
          state.modality,
          altitudeRange: state.altitudeRange,
          zones: state.zones,
        ),
      ),
    );
  }

  /// Clear the current selection / assessment.
  void clearSelection() => emit(state.copyWith(clearSelection: true));

  /// Replaces rendered zones after a backend sync.
  void updateZones(List<FlyZone> zones) {
    emit(_reassessed(state.copyWith(zones: zones)));
  }

  void _persistAltitude(AltitudeRange range) {
    unawaited(
      _settings?.setFlightAltitudeRangeAgl(
        minMetersAgl: range.minMetersAgl,
        maxMetersAgl: range.maxMetersAgl,
      ),
    );
  }

  /// Recomputes the assessment for the current selection (if any).
  MapState _reassessed(MapState next) {
    final point = next.selectedPoint;
    return next.copyWith(
      assessment: point == null
          ? null
          : _repository.assess(
              point,
              next.permission,
              next.modality,
              altitudeRange: next.altitudeRange,
              zones: next.zones,
            ),
    );
  }
}
