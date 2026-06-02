import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/view/widgets/zone_detail_card.dart';

void main() {
  testWidgets('shows MSL disclaimer when assessment has MSL-limited zones',
      (tester) async {
    const assessment = FlightAssessment(
      permission: PermissionLevel.recreational,
      modality: FlightModality.vlos,
      verdict: FlightVerdict.allowed,
      modalityAllowed: true,
      altitudeRange: AltitudeRange.openCategoryDefault,
      zones: [],
      skippedByAltitude: [
        FlyZone(
          id: 'tma',
          name: 'TMA HIGH',
          category: ZoneCategory.controlledAirspace,
          center: LatLng(-34.55, -58.65),
          radiusMeters: 50000,
          permissionsThatAllowFlight: {PermissionLevel.specialPermit},
          details: 'test',
          lowerLimitMetersMsl: 914.4,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ZoneDetailCard(
            assessment: assessment,
            point: const LatLng(-34.55, -58.65),
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('MSL altitude limits assume'),
      findsOneWidget,
    );
  });

  testWidgets('shows minimum flight requirement for selected point',
      (tester) async {
    const assessment = FlightAssessment(
      permission: PermissionLevel.recreational,
      modality: FlightModality.vlos,
      verdict: FlightVerdict.allowedWithPermission,
      modalityAllowed: true,
      altitudeRange: AltitudeRange.openCategoryDefault,
      zones: [
        FlyZone(
          id: 'ctr',
          name: 'CTR',
          category: ZoneCategory.controlledAirspace,
          center: LatLng(-34.55, -58.65),
          radiusMeters: 5000,
          permissionsThatAllowFlight: {
            PermissionLevel.authorizedCommercial,
            PermissionLevel.specialPermit,
          },
          details: 'test',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ZoneDetailCard(
            assessment: assessment,
            point: const LatLng(-34.55, -58.65),
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Minimum required:'),
      findsOneWidget,
    );
    expect(find.textContaining('Authorized / commercial'), findsOneWidget);
  });
}
