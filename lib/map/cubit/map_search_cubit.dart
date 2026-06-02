import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_repository/location_repository.dart';

part 'map_search_state.dart';

/// Search, reverse-geocode, and device-location orchestration for the map
/// screen.
class MapSearchCubit extends Cubit<MapSearchState> {
  MapSearchCubit({
    required GeocodingRepository geocodingRepository,
    required LocationRepository locationRepository,
  })  : _geocoding = geocodingRepository,
        _location = locationRepository,
        super(const MapSearchState());

  final GeocodingRepository _geocoding;
  final LocationRepository _location;

  static const _minLat = -56.0;
  static const _maxLat = -21.0;
  static const _minLon = -74.0;
  static const _maxLon = -53.0;

  Timer? _debounce;
  Object? _latestSearchRequest;

  /// Updates the in-flight query and debounces a geocoding search.
  void onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      emit(const MapSearchState());
      return;
    }

    if (trimmed.length < 2) {
      emit(
        state.copyWith(
          showResults: false,
          searching: false,
          results: const [],
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        showResults: true,
        searching: true,
        activeQuery: trimmed,
      ),
    );

    _debounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_runSearch(trimmed));
    });
  }

  /// Runs search immediately (e.g. keyboard submit).
  Future<void> submitSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed.length < 2) return;

    _debounce?.cancel();
    emit(
      state.copyWith(
        showResults: true,
        searching: true,
        activeQuery: trimmed,
      ),
    );
    await _runSearch(trimmed);
  }

  Future<void> _runSearch(String query) async {
    final requestId = Object();
    _latestSearchRequest = requestId;

    try {
      final results = await _geocoding.search(query);
      if (_latestSearchRequest != requestId) return;
      if (state.activeQuery != query) return;
      emit(
        state.copyWith(
          searching: false,
          results: results,
          searchError: results.isEmpty ? GeocodingFailure.noResults : null,
        ),
      );
    } on GeocodingException catch (e) {
      if (_latestSearchRequest != requestId) return;
      if (state.activeQuery != query) return;
      emit(
        state.copyWith(
          searching: false,
          results: const [],
          searchError: e.reason,
        ),
      );
    }
  }

  /// User picked a suggestion — focus the map on that point.
  void selectResult(GeocodeResult result) {
    _debounce?.cancel();
    _latestSearchRequest = Object();
    emit(
      state.copyWith(
        showResults: false,
        searching: false,
        results: const [],
        resolvedAddressLabel: _shortAddressLabel(result.label),
        focusPoint: result.point,
      ),
    );
  }

  /// Resolves a human-readable label for a map tap (cache-aware).
  Future<void> resolveAddressForPoint(LatLng point) async {
    try {
      final result = await _geocoding.reverse(point);
      emit(state.copyWith(resolvedAddressLabel: result.label));
    } on GeocodingException {
      emit(
        state.copyWith(
          resolvedAddressLabel: '${point.latitude.toStringAsFixed(5)}, '
              '${point.longitude.toStringAsFixed(5)}',
        ),
      );
    }
  }

  /// Centers the map on the device location.
  Future<void> locateMe() async {
    emit(
      state.copyWith(
        locating: true,
        outsideArgentina: false,
      ),
    );
    try {
      final point = await _location.currentLocation();
      emit(
        state.copyWith(
          locating: false,
          focusPoint: point,
          outsideArgentina: !_isInsideArgentina(point),
        ),
      );
    } on LocationException catch (e) {
      emit(
        state.copyWith(
          locating: false,
          locationFailure: e.reason,
        ),
      );
    }
  }

  void dismissResults() {
    if (!state.showResults &&
        state.results.isEmpty &&
        state.searchError == null &&
        !state.searching) {
      return;
    }
    emit(
      state.copyWith(
        showResults: false,
        searching: false,
        results: const [],
      ),
    );
  }

  void clearSearch() {
    _debounce?.cancel();
    _latestSearchRequest = Object();
    emit(const MapSearchState());
  }

  /// Called by the view after handling [MapSearchState.focusPoint].
  void clearFocusPoint() {
    if (state.focusPoint == null) return;
    emit(state.copyWith(clearFocusPoint: true));
  }

  void clearResolvedLabel() {
    if (state.resolvedAddressLabel == null) return;
    emit(state.copyWith(clearResolvedLabel: true));
  }

  void clearLocationMessages() {
    if (state.locationFailure == null && !state.outsideArgentina) return;
    emit(
      state.copyWith(
        clearLocationFailure: true,
        outsideArgentina: false,
      ),
    );
  }

  bool _isInsideArgentina(LatLng p) =>
      p.latitude >= _minLat &&
      p.latitude <= _maxLat &&
      p.longitude >= _minLon &&
      p.longitude <= _maxLon;

  static String _shortAddressLabel(String label) {
    final parts = label
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    return parts.take(2).join(', ');
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
