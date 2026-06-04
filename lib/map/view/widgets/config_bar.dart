import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/l10n/localized_labels.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/view/widgets/config_sheet.dart';
import 'package:where_to_fly/theme/app_theme.dart';

/// A compact bottom card summarising the current permission + modality, à la
/// Google Maps' bottom info card. Tapping opens the configuration sheet.
class ConfigBar extends StatelessWidget {
  const ConfigBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocBuilder<MapCubit, MapState>(
      builder: (context, state) {
        return Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(18),
          color: AppTheme.mapOverlaySurface(theme.brightness),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => showConfigSheet(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Icon(Icons.tune, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.permission.l10nShort(l10n)} · '
                          '${state.modality.l10nLabel(l10n)} · '
                          '${state.altitudeRange.minMetersAgl.round()}–'
                          '${state.altitudeRange.maxMetersAgl.round()} m',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l10n.tapToCheck,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
