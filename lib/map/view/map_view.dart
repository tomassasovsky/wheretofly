import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/cubit/map_search_cubit.dart';
import 'package:where_to_fly/map/cubit/map_weather_cubit.dart';
import 'package:where_to_fly/map/map_initializer.dart';
import 'package:where_to_fly/map/map_layout.dart';
import 'package:where_to_fly/map/map_zone_sync.dart';
import 'package:where_to_fly/map/view/map_search_listeners.dart';
import 'package:where_to_fly/map/view/widgets/config_bar.dart';
import 'package:where_to_fly/map/view/widgets/map_fab_column.dart';
import 'package:where_to_fly/map/view/widgets/map_google_layer.dart';
import 'package:where_to_fly/map/view/widgets/map_search_header.dart';
import 'package:where_to_fly/map/view/widgets/map_zone_detail_overlay.dart';
import 'package:where_to_fly/map/view/widgets/zone_stale_banner.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';
import 'package:where_to_fly/zone_sync/zone_sync_service.dart';

/// Full-screen map with floating overlays.
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final _mapController = MapGoogleLayerController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  var _showLegend = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState.isAuthenticated) {
        unawaited(syncMapZonesFromBackend(context));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
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

  void _clearSearchBar() {
    context.read<MapSearchCubit>().clearSearch();
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  void _clearSelection() {
    _clearSearchBar();
    context.read<MapWeatherCubit>().clear();
    context.read<MapCubit>().clearSelection();
  }

  void _checkPoint(LatLng point) {
    final searchCubit = context.read<MapSearchCubit>()..dismissResults();
    _searchFocusNode.unfocus();
    context.read<MapCubit>().checkPoint(point);
    unawaited(searchCubit.resolveAddressForPoint(point));
  }

  void _submitSearch() {
    final query = _searchController.text;
    if (query.trim().isNotEmpty) {
      context.read<MapCubit>().clearSelection();
    }
    unawaited(context.read<MapSearchCubit>().submitSearch(query));
  }

  Future<void> _zoomBy(double delta) async {
    await _mapController.zoomBy(delta);
  }

  @override
  Widget build(BuildContext context) {
    return MapSearchListeners(
      searchController: _searchController,
      searchFocusNode: _searchFocusNode,
      mapController: _mapController,
      onCheckPoint: _checkPoint,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          final mapBrightness = MapInitializer.mapBrightnessFor(
            context,
            settings.themeMode,
          );
          final isDarkMap = mapBrightness == Brightness.dark;

          return Scaffold(
            backgroundColor:
                isDarkMap ? MapInitializer.darkPlaceholderColor : null,
            body: BlocBuilder<MapCubit, MapState>(
              builder: (context, state) {
                final assessment = state.assessment;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: MapGoogleLayer(
                        controller: _mapController,
                        brightness: mapBrightness,
                        state: state,
                        onTap: _checkPoint,
                        padding: const EdgeInsets.only(
                          top: MapLayout.topOverlayInset,
                          left: 12,
                          bottom: MapLayout.bottomOverlayInset,
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
                          child: MapSearchHeader(
                            searchController: _searchController,
                            focusNode: _searchFocusNode,
                            showLegend: _showLegend,
                            onQueryChanged: _onSearchQueryChanged,
                            onSubmitSearch: _submitSearch,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: MapLayout.bottomOverlayInset,
                      child: BlocBuilder<MapSearchCubit, MapSearchState>(
                        buildWhen: (prev, next) =>
                            prev.locating != next.locating,
                        builder: (context, searchState) {
                          return MapFabColumn(
                            locating: searchState.locating,
                            onToggleLegend: () =>
                                setState(() => _showLegend = !_showLegend),
                            onLocate: () => unawaited(
                              context.read<MapSearchCubit>().locateMe(),
                            ),
                            onZoomIn: () => unawaited(_zoomBy(1)),
                            onZoomOut: () => unawaited(_zoomBy(-1)),
                          );
                        },
                      ),
                    ),
                    if (assessment != null && state.selectedPoint != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: MapLayout.bottomOverlayInset,
                        child: BlocBuilder<MapWeatherCubit, MapWeatherState>(
                          builder: (context, weatherState) {
                            return MapZoneDetailOverlay(
                              assessment: assessment,
                              point: state.selectedPoint!,
                              zoneVersion: context
                                  .read<ZoneSyncService>()
                                  .lastMetadata
                                  .version,
                              weatherState: weatherState,
                              onClose: _clearSelection,
                            );
                          },
                        ),
                      ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: MapLayout.topOverlayInset,
                      child: SafeArea(
                        bottom: false,
                        child: ZoneStaleBanner(
                          metadata:
                              context.read<ZoneSyncService>().lastMetadata,
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
          );
        },
      ),
    );
  }
}
