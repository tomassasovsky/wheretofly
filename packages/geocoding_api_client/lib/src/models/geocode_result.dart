import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// A single geocoding result: a human-readable [label] and its [point].
class GeocodeResult extends Equatable {
  const GeocodeResult({required this.label, required this.point});

  final String label;
  final LatLng point;

  @override
  List<Object?> get props => [label, point.latitude, point.longitude];
}

/// Why a geocoding lookup failed.
enum GeocodingFailure { network, noResults }

/// Thrown when geocoding fails (network error or no results).
class GeocodingException implements Exception {
  const GeocodingException(this.reason);

  final GeocodingFailure reason;
}
