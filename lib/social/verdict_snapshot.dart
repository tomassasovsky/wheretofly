import 'package:where_to_fly/l10n/gen/app_localizations.dart';

/// Shared reader for the verdict snapshot attached to a social post.
///
/// The snapshot is versioned implicitly: a v2 payload carries a `status` token
/// (4-value `VerdictStatus`), a v1 payload carries only the legacy `verdict`
/// token (3-value `FlightVerdict`). Readers prefer `status` when present and
/// fall back to `verdict` — there is no `schemaVersion` field.
abstract final class VerdictSnapshot {
  /// Map key for the legacy 3-value verdict token (v1 + v2 payloads).
  static const verdictKey = 'verdict';

  /// Map key for the v2 4-value status token (the authority when present).
  static const statusKey = 'status';

  /// Map key for the v2 list of typed verdict reasons.
  static const reasonsKey = 'reasons';

  /// Resolves the verdict token, preferring the v2 [statusKey] over the legacy
  /// [verdictKey]. Returns null when neither is present.
  static String? token(Map<String, dynamic>? snapshot) =>
      snapshot?[statusKey]?.toString() ?? snapshot?[verdictKey]?.toString();

  /// Localized label for a verdict [token].
  ///
  /// Handles both the v2 status vocabulary (`conditional`/`blocked`/
  /// `uncertain`) and the legacy v1 verdict vocabulary
  /// (`allowedWithPermission`/`notAllowed`). Any unknown token degrades to a
  /// neutral "verdict unavailable" label rather than a misleading one.
  static String label(AppLocalizations l10n, String? token) {
    return switch (token) {
      'allowed' => l10n.verdictAllowed,
      'conditional' ||
      'allowedWithPermission' =>
        l10n.verdictAllowedWithPermission,
      'blocked' || 'notAllowed' => l10n.verdictNotAllowed,
      'uncertain' => l10n.verdictUncertain,
      _ => l10n.socialVerdictUnavailable,
    };
  }
}
