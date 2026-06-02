import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:location_repository/location_repository.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/cubit/map_search_cubit.dart';
import 'package:where_to_fly/map/cubit/map_weather_cubit.dart';
import 'package:where_to_fly/map/google_map_style.dart';
import 'package:where_to_fly/map/map_zone_display.dart';
import 'package:where_to_fly/map/view/widgets/config_bar.dart';
import 'package:where_to_fly/map/view/widgets/map_legend.dart';
import 'package:where_to_fly/map/view/widgets/map_search_bar.dart';
import 'package:where_to_fly/map/view/widgets/search_results_overlay.dart';
import 'package:where_to_fly/map/view/widgets/zone_detail_card.dart';
import 'package:where_to_fly/map/view/widgets/zone_stale_banner.dart';
import 'package:where_to_fly/theme/app_theme.dart';
import 'package:where_to_fly/zone_sync/zone_sync_service.dart';

/// Converts a domain [LatLng] (latlong2) to a Google Maps [gmaps.LatLng].
gmaps.LatLng _toGoogle(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

/// Converts a Google Maps [gmaps.LatLng] back to a domain [LatLng].
LatLng _fromGoogle(gmaps.LatLng p) => LatLng(p.latitude, p.longitude);

Future<void> _syncZonesFromBackend(BuildContext context) async {
  try {
    final zones = await context.read<ZoneSyncService>().syncZones();
    if (!context.mounted) return;
    context.read<MapCubit>().updateZones(zones);
  } catch (_) {
    // Non-blocking: bundled zones remain on map.
  }
}

/// Map screen entry point — provides [MapCubit] and [MapSearchCubit].
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MapCubit(
            context.read<FlightRulesRepository>(),
            settingsRepository: context.read<SettingsRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => MapSearchCubit(
            geocodingRepository: context.read(),
            locationRepository: context.read(),
          ),
        ),
        BlocProvider(
          create: (context) {
            final authRepository = context.read<AuthRepository>();
            return MapWeatherCubit(
              weatherRepository: context.read<WeatherRepository>(),
              isAuthenticated: () async =>
                  (await authRepository.currentSession()) != null,
            );
          },
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MapCubit, MapState>(
            listenWhen: (previous, current) =>
                previous.selectedPoint != current.selectedPoint,
            listener: (context, state) {
              final point = state.selectedPoint;
              final weatherCubit = context.read<MapWeatherCubit>();
              if (point == null) {
                weatherCubit.clear();
                return;
              }
              unawaited(weatherCubit.fetchFor(point));
            },
          ),
          BlocListener<AuthCubit, AuthState>(
            listenWhen: (previous, current) =>
                !previous.isAuthenticated && current.isAuthenticated,
            listener: (context, state) {
              unawaited(_syncZonesFromBackend(context));
            },
          ),
        ],
        child: const MapView(),
      ),
    );
  }
}

/// The map view itself — a full-screen map with floating overlays, à la the
/// Google Maps app.
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  static const _argentinaCenter = gmaps.LatLng(-38.4161, -63.6167);

  /// Clears the floating search bar.
  static const _topOverlayInset = 76.0;

  /// Map attribution and right-side FABs sit just above [ConfigBar].
  static const _bottomOverlayInset = 108.0;

  gmaps.GoogleMapController? _controller;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  var _showLegend = false;
  var _zoom = 4.5;
  gmaps.LatLngBounds? _visibleBounds;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState.isAuthenticated) {
        unawaited(_syncZonesFromBackend(context));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        controller.dispose();
      } on Object {
        // Platform view may already be gone.
      }
    }
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus || !mounted) return;
    context.read<MapCubit>().clearSelection();
    final searchState = context.read<MapSearchCubit>().state;
    if (_searchController.text.trim().isNotEmpty &&
        (searchState.results.isNotEmpty ||
            searchState.searchError != null ||
            searchState.searching)) {
      context.read<MapSearchCubit>().onQueryChanged(_searchController.text);
    }
  }

  void _onSearchQueryChanged(String query) {
    if (query.trim().isNotEmpty) {
      context.read<MapCubit>().clearSelection();
    }
    context.read<MapSearchCubit>().onQueryChanged(query);
  }

  Future<void> _moveCamera(LatLng target, double zoom) async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    try {
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(_toGoogle(target), zoom),
      );
    } on PlatformException {
      // Map platform view was disposed during navigation.
    }
  }

  void _clearSearchBar() {
    context.read<MapSearchCubit>().clearSearch();
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  void _clearSelection(BuildContext context) {
    _clearSearchBar();
    context.read<MapWeatherCubit>().clear();
    context.read<MapCubit>().clearSelection();
  }

  void _checkPoint(BuildContext context, LatLng point) {
    final searchCubit = context.read<MapSearchCubit>()..dismissResults();
    _searchFocusNode.unfocus();
    context.read<MapCubit>().checkPoint(point);
    unawaited(searchCubit.resolveAddressForPoint(point));
  }

  Future<void> _goToPoint(
    LatLng point, {
    bool resolveAddress = true,
    double zoom = 12,
  }) async {
    if (!mounted) return;
    if (resolveAddress) {
      _checkPoint(context, point);
    } else {
      context.read<MapSearchCubit>().dismissResults();
      _searchFocusNode.unfocus();
      context.read<MapCubit>().checkPoint(point);
    }
    await _moveCamera(point, zoom);
  }

  String _locationErrorMessage(AppLocalizations l10n, LocationFailure reason) {
    switch (reason) {
      case LocationFailure.serviceDisabled:
        return l10n.locationServiceDisabled;
      case LocationFailure.permissionDenied:
        return l10n.locationPermissionDenied;
      case LocationFailure.permissionDeniedForever:
        return l10n.locationPermissionDeniedForever;
      case LocationFailure.unavailable:
        return l10n.locationUnavailable;
    }
  }

  Set<gmaps.Circle> _circles(MapState state, {required bool isDark}) {
    final highlightIds = {
      ...?state.assessment?.zones.map((z) => z.id),
      ...?state.assessment?.skippedByAltitude.map((z) => z.id),
    };
    final visible = MapZoneDisplay.visibleZones(
      zones: state.zones,
      bounds: _visibleBounds,
      zoom: _zoom,
      highlightIds: highlightIds,
    );

    return visible.map((zone) {
      final highlighted = highlightIds.contains(zone.id);
      final color = AppTheme.zoneColor(zone.category);
      final fillAlpha = MapZoneDisplay.fillAlpha(
        zone,
        isDark: isDark,
        highlighted: highlighted,
      );
      final strokeAlpha = MapZoneDisplay.strokeAlpha(
        isDark: isDark,
        highlighted: highlighted,
      );
      return gmaps.Circle(
        circleId: gmaps.CircleId(zone.id),
        center: _toGoogle(zone.center),
        radius: zone.radiusMeters,
        fillColor: color.withValues(alpha: fillAlpha),
        strokeColor: color.withValues(alpha: strokeAlpha),
        strokeWidth: MapZoneDisplay.strokeWidth(highlighted: highlighted),
      );
    }).toSet();
  }

  Future<void> _updateVisibleRegion() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    try {
      final bounds = await controller.getVisibleRegion();
      if (!mounted) return;
      setState(() => _visibleBounds = bounds);
    } on PlatformException {
      // Map platform view was disposed during navigation.
    }
  }

  Set<gmaps.Marker> _markers(MapState state) {
    final point = state.selectedPoint;
    if (point == null) return const {};
    return {
      gmaps.Marker(
        markerId: const gmaps.MarkerId('selected'),
        position: _toGoogle(point),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<MapSearchCubit, MapSearchState>(
          listenWhen: (prev, next) =>
              prev.resolvedAddressLabel != next.resolvedAddressLabel,
          listener: (context, state) {
            final label = state.resolvedAddressLabel;
            if (label == null) return;
            _searchController.text = label;
            context.read<MapSearchCubit>().clearResolvedLabel();
          },
        ),
        BlocListener<MapSearchCubit, MapSearchState>(
          listenWhen: (prev, next) => prev.focusPoint != next.focusPoint,
          listener: (context, state) async {
            final point = state.focusPoint;
            if (point == null) return;
            final searchCubit = context.read<MapSearchCubit>();
            final zoom = searchCubit.state.outsideArgentina ? 5.0 : 12.0;
            final resolve = state.resolvedAddressLabel == null;
            await _goToPoint(point, resolveAddress: resolve, zoom: zoom);
            searchCubit.clearFocusPoint();
          },
        ),
        BlocListener<MapSearchCubit, MapSearchState>(
          listenWhen: (prev, next) =>
              prev.locationFailure != next.locationFailure ||
              prev.outsideArgentina != next.outsideArgentina,
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context);
            if (state.locationFailure != null) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    _locationErrorMessage(l10n, state.locationFailure!),
                  ),
                ),
              );
            } else if (state.outsideArgentina) {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.outsideArgentina)),
              );
            }
            context.read<MapSearchCubit>().clearLocationMessages();
          },
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<MapCubit, MapState>(
          builder: (context, state) {
            final assessment = state.assessment;
            return Stack(
              children: [
                Positioned.fill(
                  child: gmaps.GoogleMap(
                    style: Theme.of(context).brightness == Brightness.dark
                        ? GoogleMapStyle.darkJson
                        : null,
                    colorScheme: gmaps.MapColorScheme.followSystem,
                    initialCameraPosition: const gmaps.CameraPosition(
                      target: _argentinaCenter,
                      zoom: 4.5,
                    ),
                    onMapCreated: (c) {
                      _controller = c;
                      unawaited(_updateVisibleRegion());
                    },
                    onCameraMove: (position) => _zoom = position.zoom,
                    onCameraIdle: _updateVisibleRegion,
                    onTap: (pos) => _checkPoint(context, _fromGoogle(pos)),
                    circles: _circles(
                      state,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                    markers: _markers(state),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    padding: const EdgeInsets.only(
                      top: _topOverlayInset,
                      left: 12,
                      bottom: _bottomOverlayInset,
                      right: 12,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: BlocBuilder<MapSearchCubit, MapSearchState>(
                        builder: (context, searchState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MapSearchBar(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: _onSearchQueryChanged,
                                onSubmitted: () {
                                  final query = _searchController.text;
                                  if (query.trim().isNotEmpty) {
                                    context.read<MapCubit>().clearSelection();
                                  }
                                  unawaited(
                                    context.read<MapSearchCubit>().submitSearch(
                                          query,
                                        ),
                                  );
                                },
                              ),
                              if (searchState.showResults) ...[
                                const SizedBox(height: 8),
                                SearchResultsOverlay(
                                  searching: searchState.searching,
                                  results: searchState.results,
                                  error: searchState.searchError,
                                  onResultSelected: (result) => context
                                      .read<MapSearchCubit>()
                                      .selectResult(result),
                                ),
                              ],
                              if (_showLegend) ...[
                                const SizedBox(height: 8),
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: MapLegend(),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: _bottomOverlayInset,
                  child: BlocBuilder<MapSearchCubit, MapSearchState>(
                    buildWhen: (prev, next) => prev.locating != next.locating,
                    builder: (context, searchState) {
                      return _MapFabColumn(
                        locating: searchState.locating,
                        onToggleLegend: () =>
                            setState(() => _showLegend = !_showLegend),
                        onLocate: () => unawaited(
                          context.read<MapSearchCubit>().locateMe(),
                        ),
                      );
                    },
                  ),
                ),
                if (assessment != null && state.selectedPoint != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: _bottomOverlayInset,
                    child: BlocBuilder<MapWeatherCubit, MapWeatherState>(
                      builder: (context, weatherState) {
                        return _ZoneDetailOverlay(
                          assessment: assessment,
                          point: state.selectedPoint!,
                          zoneVersion: context
                              .read<ZoneSyncService>()
                              .lastMetadata
                              .version,
                          weatherState: weatherState,
                          onClose: () => _clearSelection(context),
                        );
                      },
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: _topOverlayInset,
                  child: SafeArea(
                    bottom: false,
                    child: ZoneStaleBanner(
                      metadata: context.read<ZoneSyncService>().lastMetadata,
                    ),
                  ),
                ),
                const Positioned(
                  left: 12,
                  right: 12,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ConfigBar(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ZoneDetailOverlay extends StatelessWidget {
  const _ZoneDetailOverlay({
    required this.assessment,
    required this.point,
    required this.weatherState,
    required this.onClose,
    this.zoneVersion,
  });

  static const _animationDuration = Duration(milliseconds: 280);
  static const _animationCurve = Curves.easeInOutCubic;

  final FlightAssessment assessment;
  final LatLng point;
  final MapWeatherState weatherState;
  final VoidCallback onClose;
  final String? zoneVersion;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: _animationDuration,
      curve: _animationCurve,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      child: ZoneDetailCard(
        assessment: assessment,
        point: point,
        zoneVersion: zoneVersion,
        weatherState: weatherState,
        onClose: onClose,
      ),
    );
  }
}

class _MapFabColumn extends StatelessWidget {
  const _MapFabColumn({
    required this.locating,
    required this.onToggleLegend,
    required this.onLocate,
  });

  final bool locating;
  final VoidCallback onToggleLegend;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'legend',
          onPressed: onToggleLegend,
          tooltip: l10n.permissionsAndResources,
          child: const Icon(Icons.layers_outlined),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'locate',
          onPressed: locating ? null : onLocate,
          tooltip: l10n.locateMe,
          child: locating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
        ),
      ],
    );
  }
}
