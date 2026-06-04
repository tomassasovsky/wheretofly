import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/l10n/localized_labels.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';

/// Bottom sheet to configure the held permission and intended flight modality.
/// Selections update the [MapCubit] live and are persisted.
Future<void> showConfigSheet(BuildContext context) {
  final cubit = context.read<MapCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _ConfigSheet(),
    ),
  );
}

class _ConfigSheet extends StatelessWidget {
  const _ConfigSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocBuilder<MapCubit, MapState>(
      builder: (context, state) {
        final cubit = context.read<MapCubit>();
        final maxAltitude = state.permission.maxPlannedAltitudeMetersAgl;
        final range = state.altitudeRange;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) => ListView(
            key: const ValueKey('config_sheet_scroll'),
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              _SectionTitle(l10n.yourPermission),
              for (final level in PermissionLevel.values)
                _OptionTile(
                  title: level.l10nLabel(l10n),
                  subtitle: level.l10nConfigHint(l10n),
                  selected: state.permission == level,
                  onTap: () => cubit.selectPermission(level),
                ),
              const SizedBox(height: 12),
              _SectionTitle(l10n.flightModality),
              for (final modality in FlightModality.values)
                _OptionTile(
                  title: modality.l10nLabel(l10n),
                  subtitle: modality.l10nDescription(l10n),
                  selected: state.modality == modality,
                  locked:
                      state.permission.rank < modality.minimumPermission.rank,
                  onTap: state.permission.rank < modality.minimumPermission.rank
                      ? null
                      : () => cubit.selectModality(modality),
                ),
              const SizedBox(height: 12),
              _SectionTitle(l10n.plannedAltitude),
              Text(
                l10n.altitudeRangeMeters(
                  range.minMetersAgl.round().toString(),
                  range.maxMetersAgl.round().toString(),
                ),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              RangeSlider(
                values: RangeValues(
                  range.minMetersAgl,
                  range.maxMetersAgl,
                ),
                max: maxAltitude,
                divisions: maxAltitude.round(),
                labels: RangeLabels(
                  l10n.altitudeMeters(range.minMetersAgl.round().toString()),
                  l10n.altitudeMeters(range.maxMetersAgl.round().toString()),
                ),
                onChanged: (values) => cubit.selectAltitudeRange(
                  values.start,
                  values.end,
                ),
              ),
              Text(
                state.permission.isOpenCategoryOnly
                    ? l10n.plannedAltitudeHintOpen
                    : l10n.plannedAltitudeHintExtended,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.tapHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('map_resources_link'),
                onPressed: () => ResourcesRoute(
                  highlight: state.permission.id,
                ).push<void>(context),
                icon: const Icon(Icons.help_outline),
                label: Text(l10n.permissionsAndResources),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : null,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: color,
        ),
        title: Row(
          children: [
            Flexible(child: Text(title)),
            if (locked) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.lock_outline,
                size: 16,
                color: theme.colorScheme.error,
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}
