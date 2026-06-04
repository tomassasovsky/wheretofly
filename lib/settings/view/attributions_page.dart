import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';

/// Open-source package licenses plus map and weather data attributions.
///
/// Uses Flutter's built-in [LicensePage], which lists [LicenseRegistry] entries
/// and licenses collected from dependencies at build time.
class AttributionsPage extends StatelessWidget {
  const AttributionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LicensePage(
      applicationName: l10n.appTitle,
    );
  }
}
