import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/zone_sync/zone_sync_service.dart';

/// Pulls the latest zones from the backend and updates [MapCubit].
Future<void> syncMapZonesFromBackend(BuildContext context) async {
  try {
    final zones = await context.read<ZoneSyncService>().syncZones();
    if (!context.mounted) return;
    context.read<MapCubit>().updateZones(zones);
  } catch (_) {
    // Non-blocking: bundled zones remain on map.
  }
}
