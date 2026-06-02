import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';

/// A single actionable resource: a step or an external link to obtain a
/// permission / authorization.
class PermitResource {
  const PermitResource({
    required this.title,
    required this.description,
    this.url,
  });

  final String title;
  final String description;

  /// Optional external URL (official ANAC / Argentina.gob.ar pages).
  final String? url;
}

/// A block of resources tied to a given permission level.
class PermitGuide {
  const PermitGuide({
    required this.level,
    required this.summary,
    required this.resources,
  });

  final PermissionLevel level;
  final String summary;
  final List<PermitResource> resources;
}

/// Builds the localized permit guides for each permission level. URLs point to
/// official ANAC / Argentina.gob.ar resources; the surrounding text follows the
/// active locale.
List<PermitGuide> buildPermitGuides(AppLocalizations l10n) {
  return [
    PermitGuide(
      level: PermissionLevel.recreational,
      summary: l10n.resRecSummary,
      resources: [
        PermitResource(
          title: l10n.r1Title,
          description: l10n.r1Desc,
          url:
              'https://www.argentina.gob.ar/anac/nuevo-marco-normativo-para-la-operacion-de-drones',
        ),
        PermitResource(title: l10n.r2Title, description: l10n.r2Desc),
      ],
    ),
    PermitGuide(
      level: PermissionLevel.registeredPilot,
      summary: l10n.resRegSummary,
      resources: [
        PermitResource(
          title: l10n.r3Title,
          description: l10n.r3Desc,
          url: 'https://www.argentina.gob.ar/anac/rpa-rpas',
        ),
        PermitResource(
          title: l10n.r4Title,
          description: l10n.r4Desc,
          url: 'https://tramitesadistancia.gob.ar',
        ),
      ],
    ),
    PermitGuide(
      level: PermissionLevel.authorizedCommercial,
      summary: l10n.resComSummary,
      resources: [
        PermitResource(
          title: l10n.r5Title,
          description: l10n.r5Desc,
          url: 'https://www.argentina.gob.ar/anac/rpa-rpas',
        ),
        PermitResource(
          title: l10n.r6Title,
          description: l10n.r6Desc,
          url: 'https://www.argentina.gob.ar/anac',
        ),
      ],
    ),
    PermitGuide(
      level: PermissionLevel.specialPermit,
      summary: l10n.resSpecSummary,
      resources: [
        PermitResource(
          title: l10n.r7Title,
          description: l10n.r7Desc,
          url: 'https://www.argentina.gob.ar/anac',
        ),
        PermitResource(
          title: l10n.r8Title,
          description: l10n.r8Desc,
          url: 'https://www.argentina.gob.ar/parquesnacionales',
        ),
        PermitResource(
          title: l10n.r9Title,
          description: l10n.r9Desc,
          url: 'https://www.argentina.gob.ar/anac',
        ),
      ],
    ),
  ];
}
