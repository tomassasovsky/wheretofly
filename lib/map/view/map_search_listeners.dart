import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/cubit/map_search_cubit.dart';
import 'package:where_to_fly/map/map_camera_controller.dart';

/// Side effects for [MapSearchCubit]: address labels, camera focus, snackbars.
class MapSearchListeners extends StatelessWidget {
  const MapSearchListeners({
    required this.searchController,
    required this.searchFocusNode,
    required this.mapController,
    required this.onCheckPoint,
    required this.child,
    super.key,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final MapCameraController mapController;
  final ValueChanged<LatLng> onCheckPoint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MapSearchCubit, MapSearchState>(
          listenWhen: (prev, next) =>
              prev.resolvedAddressLabel != next.resolvedAddressLabel,
          listener: (context, state) {
            final label = state.resolvedAddressLabel;
            if (label == null) return;
            searchController.text = label;
            context.read<MapSearchCubit>().clearResolvedLabel();
          },
        ),
        BlocListener<MapSearchCubit, MapSearchState>(
          listenWhen: (prev, next) => prev.focusPoint != next.focusPoint,
          listener: (context, state) async {
            final point = state.focusPoint;
            if (point == null) return;
            final searchCubit = context.read<MapSearchCubit>();
            const zoom = 12.0;
            final resolve = state.resolvedAddressLabel == null;
            await _goToPoint(
              context,
              point,
              resolveAddress: resolve,
              zoom: zoom,
            );
            searchCubit.clearFocusPoint();
          },
        ),
      ],
      child: child,
    );
  }

  Future<void> _goToPoint(
    BuildContext context,
    LatLng point, {
    required bool resolveAddress,
    required double zoom,
  }) async {
    if (resolveAddress) {
      onCheckPoint(point);
    } else {
      context.read<MapSearchCubit>().dismissResults();
      searchFocusNode.unfocus();
      context.read<MapCubit>().checkPoint(point);
    }
    await mapController.moveTo(point, zoom: zoom);
  }
}
