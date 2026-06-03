import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/cubit/map_weather_cubit.dart';
import 'package:where_to_fly/map/view/widgets/zone_detail_card.dart';

/// Animated wrapper for the zone detail card on the map stack.
class MapZoneDetailOverlay extends StatelessWidget {
  const MapZoneDetailOverlay({
    required this.assessment,
    required this.point,
    required this.weatherState,
    required this.onClose,
    this.zoneVersion,
    super.key,
  });

  static const _animationDuration = Duration(milliseconds: 280);
  static const _animationCurve = Curves.easeInOutCubic;

  final FlightAssessment assessment;
  final LatLng point;
  final MapWeatherState weatherState;
  final VoidCallback onClose;
  final String? zoneVersion;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: _animationDuration,
      curve: _animationCurve,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      child: ZoneDetailCard(
        assessment: assessment,
        point: point,
        zoneVersion: zoneVersion,
        weatherState: weatherState,
        onClose: onClose,
      ),
    );
  }
}
