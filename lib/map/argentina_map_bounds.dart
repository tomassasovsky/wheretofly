import 'package:argentina_bounds/argentina_bounds.dart';
import 'package:latlong2/latlong.dart';

/// Whether the given point lies inside Argentina for warning purposes.
///
/// Selection is always allowed; callers show a warning when this is false.
abstract final class ArgentinaMapBounds {
  static bool contains(LatLng point) => ArgentinaBounds.contains(point);
}
