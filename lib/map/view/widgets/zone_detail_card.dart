import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/app/app_mode.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/auth/auth_navigation.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/l10n/localized_labels.dart';
import 'package:where_to_fly/map/cubit/map_weather_cubit.dart';
import 'package:where_to_fly/map/view/widgets/weather_advisory_card.dart';
import 'package:where_to_fly/social/create_post_draft.dart';
import 'package:where_to_fly/theme/app_theme.dart';

/// Floating overlay card summarising flight restrictions for the selected
/// point — shown on the map stack, not as a modal bottom sheet.
class ZoneDetailCard extends StatelessWidget {
  const ZoneDetailCard({
    required this.assessment,
    required this.point,
    required this.onClose,
    this.weatherState,
    this.zoneVersion,
    super.key,
  });

  final FlightAssessment assessment;
  final LatLng point;
  final VoidCallback onClose;
  final MapWeatherState? weatherState;
  final String? zoneVersion;

  // Exhaustive switches on [VerdictStatus] (no `default`) so the next status
  // addition is a compile error, not a silent wrong color.
  Color _verdictColor(BuildContext context) {
    switch (assessment.status) {
      case VerdictStatus.allowed:
        return const Color(0xFF2E7D32);
      case VerdictStatus.conditional:
        return const Color(0xFFF9A825);
      case VerdictStatus.blocked:
        return const Color(0xFFD32F2F);
      case VerdictStatus.uncertain:
        return const Color(0xFF607D8B);
    }
  }

  IconData get _verdictIcon {
    switch (assessment.status) {
      case VerdictStatus.allowed:
        return Icons.check_circle;
      case VerdictStatus.conditional:
        return Icons.verified_user;
      case VerdictStatus.blocked:
        return Icons.block;
      case VerdictStatus.uncertain:
        return Icons.help_outline;
    }
  }

  String _headline(AppLocalizations l10n) {
    switch (assessment.status) {
      case VerdictStatus.allowed:
        return l10n.verdictAllowed;
      case VerdictStatus.conditional:
        return l10n.verdictAllowedWithPermission;
      case VerdictStatus.blocked:
        return l10n.verdictNotAllowed;
      case VerdictStatus.uncertain:
        return l10n.verdictUncertain;
    }
  }

  /// Localized copy for reasons rendered in the dedicated reasons section.
  /// [VerdictReason.mslGroundElevationUnknown] is intentionally absent — it
  /// renders via its own MSL disclaimer banner, never twice.
  String? _reasonText(AppLocalizations l10n, VerdictReason reason) {
    switch (reason) {
      case VerdictReason.zoneDataUnavailable:
        return l10n.reasonZoneDataUnavailable;
      case VerdictReason.mslGroundElevationUnknown:
        return null;
    }
  }

  PermissionLevel? _permitToHighlight() {
    return assessment.minimumRequiredPermission ??
        (!assessment.modalityAllowed
            ? assessment.modality.minimumPermission
            : null);
  }

  void _openPermitResources(BuildContext context) {
    final highlight = _permitToHighlight();
    ResourcesRoute(
      highlight: highlight?.id,
    ).push<void>(context);
  }

  void _shareFlyCheck(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (!authState.isAuthenticated) {
      openLogin(context);
      return;
    }
    CreatePostRoute(
      $extra: CreatePostDraft(
        point: point,
        assessment: assessment,
        zoneVersion: zoneVersion,
      ),
    ).push<void>(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = _verdictColor(context);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      color: AppTheme.mapOverlaySurface(theme.brightness),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.38,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_verdictIcon, color: color, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _headline(l10n),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.done,
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
              Text(
                l10n.permissionConsidered(
                  assessment.permission.l10nLabel(l10n),
                  assessment.permission.l10nCategory(l10n),
                ),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${l10n.flightModality}: '
                '${assessment.modality.l10nLabel(l10n)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                l10n.altitudeRangeConsidered(
                  assessment.altitudeRange.minMetersAgl.round().toString(),
                  assessment.altitudeRange.maxMetersAgl.round().toString(),
                ),
                style: theme.textTheme.bodySmall,
              ),
              if (assessment.minimumRequiredPermission case final minimum?) ...[
                Text(
                  l10n.minimumFlightRequirement(
                    minimum.l10nLabel(l10n),
                    minimum.l10nCategory(l10n),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Text(
                  l10n.flightNotPossibleHere,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFD32F2F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (weatherState != null) ...[
                _WeatherSection(state: weatherState!),
                const SizedBox(height: 12),
              ],
              if (!assessment.modalityAllowed) ...[
                _InfoBanner(
                  text: l10n.modalityRequires(
                    assessment.modality.l10nLabel(l10n),
                    assessment.modality.minimumPermission.l10nCategory(l10n),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (assessment.zones.isEmpty &&
                  assessment.modalityAllowed &&
                  assessment.status != VerdictStatus.uncertain)
                Text(l10n.noZones, style: theme.textTheme.bodyMedium)
              else if (assessment.zones.isNotEmpty)
                ...assessment.zones.map(
                  (z) => _ZoneRow(
                    zone: z,
                    covered: z.allowsFlightFor(assessment.permission),
                  ),
                ),
              ..._buildReasonsSection(l10n, theme),
              if (assessment.hasControlledAirspaceZones &&
                  assessment.status != VerdictStatus.blocked) ...[
                const SizedBox(height: 8),
                _InfoBanner(
                  text: l10n.controlledAirspaceCoordination,
                  warning: true,
                ),
              ],
              if (assessment.hasMslAltitudeUncertainty) ...[
                const SizedBox(height: 8),
                _InfoBanner(text: l10n.mslGroundElevationDisclaimer),
              ],
              if (assessment.skippedByAltitude.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.zonesSkippedByAltitude,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                ...assessment.skippedByAltitude.map(
                  (z) => _ZoneRow(
                    zone: z,
                    covered: true,
                    skippedByAltitude: true,
                  ),
                ),
              ],
              if (!AppMode.isMapOnly) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _shareFlyCheck(context),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l10n.socialShareFlyCheck),
                ),
              ],
              if (assessment.status == VerdictStatus.blocked) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _openPermitResources(context),
                  icon: const Icon(Icons.assignment_outlined),
                  label: Text(l10n.howToRequest),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Reasons section below the headline. Renders every reason that lacks a
  /// dedicated banner (so MSL never double-renders) with a one-line heading.
  List<Widget> _buildReasonsSection(AppLocalizations l10n, ThemeData theme) {
    final texts = [
      for (final reason in assessment.reasons)
        if (_reasonText(l10n, reason) case final text?) text,
    ];
    if (texts.isEmpty) return const [];
    return [
      const SizedBox(height: 8),
      Text(
        l10n.uncertainReasonsHeading,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      for (final text in texts) ...[
        const SizedBox(height: 8),
        _InfoBanner(text: text, warning: true),
      ],
    ];
  }
}

class _WeatherSection extends StatelessWidget {
  const _WeatherSection({required this.state});

  final MapWeatherState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (state.status) {
      case MapWeatherStatus.loading:
        return Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(l10n.weatherLoading),
          ],
        );
      case MapWeatherStatus.loaded:
        final snapshot = state.snapshot;
        if (snapshot == null) return const SizedBox.shrink();
        final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;
        return WeatherAdvisoryCard(
          snapshot: snapshot,
          showSaveAlert: isAuthenticated,
        );
      case MapWeatherStatus.error:
        return _InfoBanner(text: _weatherErrorText(l10n, state.errorMessage));
      case MapWeatherStatus.idle:
        return const SizedBox.shrink();
    }
  }
}

String _weatherErrorText(AppLocalizations l10n, String? code) {
  return switch (code) {
    'weather_network_timeout' => l10n.weatherNetworkTimeout,
    'weather_rate_limited' => l10n.weatherRateLimited,
    'weather_upstream_unavailable' => l10n.weatherUpstreamUnavailable,
    'weather_fetch_failed' => l10n.weatherFetchFailed,
    _ => l10n.weatherFetchFailed,
  };
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.text,
    this.warning = false,
  });

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = warning
        ? (
            background: theme.colorScheme.secondaryContainer,
            foreground: theme.colorScheme.onSecondaryContainer,
          )
        : (
            background: theme.colorScheme.errorContainer,
            foreground: theme.colorScheme.onErrorContainer,
          );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.zone,
    required this.covered,
    this.skippedByAltitude = false,
  });

  final FlyZone zone;
  final bool covered;
  final bool skippedByAltitude;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.zoneColor(zone.category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.name, style: theme.textTheme.titleSmall),
                Text(
                  zone.category.l10nLabel(l10n),
                  style: theme.textTheme.bodySmall,
                ),
                if (zone.hasVerticalLimits)
                  Text(
                    zone.l10nVerticalExtent(l10n),
                    style: theme.textTheme.bodySmall,
                  ),
                if (!skippedByAltitude)
                  Text(
                    covered ? l10n.coversZone : l10n.notCoversZone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: covered
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFD32F2F),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    l10n.zoneSkippedAltitude,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
