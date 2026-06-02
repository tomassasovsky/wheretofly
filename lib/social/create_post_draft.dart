import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:latlong2/latlong.dart';

/// Payload for creating a post from the map fly-check overlay.
class CreatePostDraft {
  const CreatePostDraft({
    required this.point,
    required this.assessment,
    this.zoneVersion,
  });

  final LatLng point;
  final FlightAssessment assessment;
  final String? zoneVersion;

  Map<String, dynamic> toVerdictSnapshot() {
    return {
      'point': {'lat': point.latitude, 'lon': point.longitude},
      'permissionId': assessment.permission.id,
      'modalityId': assessment.modality.id,
      'verdict': assessment.verdict.name,
      'altitudeMinMetersAgl': assessment.altitudeRange.minMetersAgl,
      'altitudeMaxMetersAgl': assessment.altitudeRange.maxMetersAgl,
    };
  }
}
