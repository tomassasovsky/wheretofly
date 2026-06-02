import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/resources/view/resources_page.dart';

void main() {
  testWidgets('highlights the matching permission guide card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ResourcesPage(
          highlightPermission: PermissionLevel.authorizedCommercial,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Recommended for this location'),
      findsOneWidget,
    );
    expect(find.textContaining('Authorized / commercial'), findsWidgets);
  });

  testWidgets('does not highlight when no permission is passed',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ResourcesPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Recommended for this location'), findsNothing);
  });
}
