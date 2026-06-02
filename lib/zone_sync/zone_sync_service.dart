import 'package:backend_zones_api_client/backend_zones_api_client.dart';
import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:zones_api_client/zones_api_client.dart';

/// Reloads zone data from configured live feeds over the bundled baseline.
class ZoneSyncService {
  ZoneSyncService({
    required this.backendZonesClient,
    this.madhelEnabled = true,
  });

  final BackendZonesApiClient backendZonesClient;
  final bool madhelEnabled;

  ZoneFeedMetadata get lastMetadata => backendZonesClient.lastMetadata;

  Future<List<FlyZone>> syncZones() async {
    final repo = await FlightRulesRepository.load(
      geojson: backendZonesClient,
      madhel: madhelEnabled ? MadhelZonesApiClient() : null,
    );
    return repo.zones;
  }
}
