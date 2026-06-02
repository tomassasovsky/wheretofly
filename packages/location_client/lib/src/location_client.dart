import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Why a location request failed.
enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

/// Thrown by [LocationClient] when the device location cannot be obtained.
class LocationException implements Exception {
  const LocationException(this.reason);

  final LocationFailure reason;
}

/// Data client: thin wrapper around the `geolocator` plugin. It normalises
/// permission handling and returns a plain [LatLng], throwing a typed
/// [LocationException] on failure.
class LocationClient {
  const LocationClient();

  Future<LatLng> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationFailure.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.permissionDeniedForever);
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      throw const LocationException(LocationFailure.unavailable);
    }
  }
}
