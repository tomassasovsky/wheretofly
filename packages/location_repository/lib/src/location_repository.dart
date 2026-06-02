import 'package:latlong2/latlong.dart';
import 'package:location_client/location_client.dart';

/// Repository: exposes the device location as a domain [LatLng], sitting
/// between the [LocationClient] (data) and the business logic layer.
class LocationRepository {
  const LocationRepository({LocationClient client = const LocationClient()})
      : _client = client;

  final LocationClient _client;

  /// Returns the device's current location, throwing a [LocationException]
  /// (with a typed [LocationFailure]) when it cannot be obtained.
  Future<LatLng> currentLocation() => _client.getCurrentPosition();
}
