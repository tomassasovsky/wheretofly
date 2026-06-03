import 'package:backend_zones_api_client/backend_zones_api_client.dart';
import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:zones_api_client/zones_api_client.dart';

/// Reloads zone data from the backend feed.
class ZoneSyncService {
  ZoneSyncService({required this.backendZonesClient});

  final BackendZonesApiClient backendZonesClient;

  ZoneFeedMetadata get lastMetadata => backendZonesClient.lastMetadata;

  Future<List<FlyZone>> syncZones() async {
    final repo = await FlightRulesRepository.load(feed: backendZonesClient);
    return repo.zones;
  }
}
