import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/view/widgets/zone_detail_card.dart';

void main() {
  testWidgets('shows MSL disclaimer when assessment has MSL-limited zones',
      (tester) async {
    final assessment = FlightAssessment(
      permission: PermissionLevel.recreational,
      modality: FlightModality.vlos,
      status: VerdictStatus.allowed,
      modalityAllowed: true,
      altitudeRange: AltitudeRange.openCategoryDefault,
      zones: const [],
      reasons: const [VerdictReason.mslGroundElevationUnknown],
      skippedByAltitude: const [
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
    final assessment = FlightAssessment(
      permission: PermissionLevel.recreational,
      modality: FlightModality.vlos,
      status: VerdictStatus.conditional,
      modalityAllowed: true,
      altitudeRange: AltitudeRange.openCategoryDefault,
      zones: const [
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

  Future<void> pumpCard(
    WidgetTester tester,
    FlightAssessment assessment,
  ) async {
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
  }

  FlightAssessment assessmentWith({
    required VerdictStatus status,
    List<VerdictReason> reasons = const [],
    List<FlyZone> zones = const [],
  }) =>
      FlightAssessment(
        permission: PermissionLevel.recreational,
        modality: FlightModality.vlos,
        status: status,
        modalityAllowed: true,
        altitudeRange: AltitudeRange.openCategoryDefault,
        zones: zones,
        reasons: reasons,
      );

  const controlledZone = FlyZone(
    id: 'ctr',
    name: 'CTR',
    category: ZoneCategory.controlledAirspace,
    center: LatLng(-34.55, -58.65),
    radiusMeters: 5000,
    permissionsThatAllowFlight: {PermissionLevel.authorizedCommercial},
    details: 'test',
  );

  testWidgets('renders allowed headline and icon', (tester) async {
    await pumpCard(tester, assessmentWith(status: VerdictStatus.allowed));
    expect(find.text('You can fly here'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('renders conditional headline and icon', (tester) async {
    await pumpCard(
      tester,
      assessmentWith(
        status: VerdictStatus.conditional,
        zones: [controlledZone],
      ),
    );
    expect(find.text('You can fly with your permit'), findsOneWidget);
    expect(find.byIcon(Icons.verified_user), findsOneWidget);
  });

  testWidgets('renders blocked headline, icon and permit CTA', (tester) async {
    await pumpCard(tester, assessmentWith(status: VerdictStatus.blocked));
    expect(find.text("You can't fly here"), findsOneWidget);
    expect(find.byIcon(Icons.block), findsOneWidget);
    expect(find.text('How to request a permit'), findsOneWidget);
  });

  testWidgets(
    'renders uncertain headline, reason, hides noZones and permit CTA',
    (tester) async {
      await pumpCard(
        tester,
        assessmentWith(
          status: VerdictStatus.uncertain,
          reasons: [VerdictReason.zoneDataUnavailable],
        ),
      );
      expect(find.text('Verify manually'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.text("Why we're not sure"), findsOneWidget);
      expect(
        find.textContaining('Zone data is unavailable'),
        findsOneWidget,
      );
      // noZones contradiction copy must not appear under uncertainty.
      expect(
        find.textContaining('No restricted zones registered'),
        findsNothing,
      );
      // An uncertain verdict is not "you need a permit".
      expect(find.text('How to request a permit'), findsNothing);
    },
  );

  testWidgets(
    'controlled-airspace banner shows for uncertain, hidden for blocked',
    (tester) async {
      await pumpCard(
        tester,
        assessmentWith(
          status: VerdictStatus.uncertain,
          reasons: [VerdictReason.zoneDataUnavailable],
          zones: [controlledZone],
        ),
      );
      expect(find.textContaining('Controlled airspace nearby'), findsOneWidget);

      await pumpCard(
        tester,
        assessmentWith(status: VerdictStatus.blocked, zones: [controlledZone]),
      );
      expect(find.textContaining('Controlled airspace nearby'), findsNothing);
    },
  );
}
