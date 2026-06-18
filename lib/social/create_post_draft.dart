import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/social/verdict_snapshot.dart';

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
    // Snapshot version gate: the presence of `status` marks a v2 payload.
    // v1 payloads have only `verdict`. Deserializers prefer `status` when
    // present and fall back to `verdict` otherwise — no `schemaVersion` field
    // (it would be a redundant second discriminator). A future v3 can add
    // `schemaVersion` and detect v2 as `status` present yet `schemaVersion`
    // absent.
    return {
      'point': {'lat': point.latitude, 'lon': point.longitude},
      'permissionId': assessment.permission.id,
      'modalityId': assessment.modality.id,
      // legacy 3-value, for old readers
      VerdictSnapshot.verdictKey: assessment.verdict.name,
      // v2 authority (4-value)
      VerdictSnapshot.statusKey: assessment.status.name,
      VerdictSnapshot.reasonsKey:
          assessment.reasons.map((r) => r.name).toList(),
      'altitudeMinMetersAgl': assessment.altitudeRange.minMetersAgl,
      'altitudeMaxMetersAgl': assessment.altitudeRange.maxMetersAgl,
    };
  }
}
