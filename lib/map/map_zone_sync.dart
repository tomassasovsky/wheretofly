import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/map_zone_display.dart';
import 'package:where_to_fly/zone_sync/zone_sync_service.dart';
import 'package:zones_api_client/zones_api_client.dart';

/// Pulls the latest zones for the map and updates [MapCubit].
Future<void> syncMapZonesFromBackend(BuildContext context) async {
  try {
    final zones = MapZoneDisplay.openAipOnly
        ? await _loadOpenAipExportZones()
        : await context.read<ZoneSyncService>().syncZones();
    if (!context.mounted) return;
    context.read<MapCubit>().updateZones(zones);
  } catch (_) {
    // Non-blocking: existing map zones remain.
  }
}

Future<List<FlyZone>> _loadOpenAipExportZones() async {
  final data = await OpenAipExportZonesApiClient().fetchZones();
  return FlightRulesRepository.fromZoneData(data).zones;
}
