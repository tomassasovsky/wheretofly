part of 'map_search_cubit.dart';

/// State for map search, reverse geocoding, and location lookup.
class MapSearchState extends Equatable {
  const MapSearchState({
    this.activeQuery = '',
    this.showResults = false,
    this.searching = false,
    this.results = const [],
    this.searchError,
    this.locating = false,
    this.resolvedAddressLabel,
    this.focusPoint,
    this.locationFailure,
    this.outsideArgentina = false,
  });

  final String activeQuery;
  final bool showResults;
  final bool searching;
  final List<GeocodeResult> results;
  final GeocodingFailure? searchError;
  final bool locating;

  /// Label to show in the search field after reverse geocode or pick.
  final String? resolvedAddressLabel;

  /// When set, the map should move here and then call
  /// [MapSearchCubit.clearFocusPoint].
  final LatLng? focusPoint;
  final LocationFailure? locationFailure;
  final bool outsideArgentina;

  MapSearchState copyWith({
    String? activeQuery,
    bool? showResults,
    bool? searching,
    List<GeocodeResult>? results,
    GeocodingFailure? searchError,
    bool clearSearchError = false,
    bool? locating,
    String? resolvedAddressLabel,
    bool clearResolvedLabel = false,
    LatLng? focusPoint,
    bool clearFocusPoint = false,
    LocationFailure? locationFailure,
    bool clearLocationFailure = false,
    bool? outsideArgentina,
  }) {
    return MapSearchState(
      activeQuery: activeQuery ?? this.activeQuery,
      showResults: showResults ?? this.showResults,
      searching: searching ?? this.searching,
      results: results ?? this.results,
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      locating: locating ?? this.locating,
      resolvedAddressLabel: clearResolvedLabel
          ? null
          : (resolvedAddressLabel ?? this.resolvedAddressLabel),
      focusPoint: clearFocusPoint ? null : (focusPoint ?? this.focusPoint),
      locationFailure: clearLocationFailure
          ? null
          : (locationFailure ?? this.locationFailure),
      outsideArgentina: outsideArgentina ?? this.outsideArgentina,
    );
  }

  @override
  List<Object?> get props => [
        activeQuery,
        showResults,
        searching,
        results,
        searchError,
        locating,
        resolvedAddressLabel,
        focusPoint,
        locationFailure,
        outsideArgentina,
      ];
}
