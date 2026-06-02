// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const point = LatLng(-34.6103764, -58.3622067); // Puerto Madero
  final repo = FlightRulesRepository();

  print('=== Puerto Madero ($point) ===\n');
  for (final z in repo.zonesAt(point)) {
    final dist = _distanceMeters(z.center, point);
    print('- ${z.name}');
    print(
      '  id=${z.id} category=${z.category.id} dist=${dist.round()}m '
      'r=${z.radiusMeters.round()}m',
    );
    print(
      '  allows=${z.permissionsThatAllowFlight.map((p) => p.id).join(", ")}',
    );
  }

  print('\n=== Assessments (VLOS, 0-122m) ===');
  for (final p in PermissionLevel.values) {
    final a = repo.assess(point, p, FlightModality.vlos);
    print(
      '${p.id}: ${a.verdict.name} zones=${a.zones.length} '
      'blocking=${a.blockingZones.map((z) => z.name).join("; ")}',
    );
  }
}

double _distanceMeters(LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  final dLat = _toRad(b.latitude - a.latitude);
  final dLon = _toRad(b.longitude - a.longitude);
  final lat1 = _toRad(a.latitude);
  final lat2 = _toRad(b.latitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
  return earthRadius * 2 * math.asin(math.min(1, math.sqrt(h)));
}

double _toRad(double deg) => deg * (math.pi / 180.0);
