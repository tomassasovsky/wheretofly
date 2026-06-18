import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/social/create_post_draft.dart';

void main() {
  group('CreatePostDraft.toVerdictSnapshot', () {
    CreatePostDraft draftWith({
      required VerdictStatus status,
      List<VerdictReason> reasons = const [],
    }) =>
        CreatePostDraft(
          point: const LatLng(-34.55, -58.65),
          assessment: FlightAssessment(
            permission: PermissionLevel.recreational,
            modality: FlightModality.vlos,
            status: status,
            modalityAllowed: true,
            altitudeRange: AltitudeRange.openCategoryDefault,
            zones: const [],
            reasons: reasons,
          ),
        );

    test('emits status, reasons and legacy verdict', () {
      final snapshot = draftWith(
        status: VerdictStatus.uncertain,
        reasons: [VerdictReason.zoneDataUnavailable],
      ).toVerdictSnapshot();

      expect(snapshot['status'], 'uncertain');
      expect(snapshot['reasons'], ['zoneDataUnavailable']);
      // Legacy field stays for v1 readers; uncertain maps conservatively.
      expect(snapshot['verdict'], 'notAllowed');
    });

    test('conditional status keeps allowedWithPermission legacy verdict', () {
      final snapshot =
          draftWith(status: VerdictStatus.conditional).toVerdictSnapshot();

      expect(snapshot['status'], 'conditional');
      expect(snapshot['verdict'], 'allowedWithPermission');
      expect(snapshot['reasons'], isEmpty);
    });
  });
}
