import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_repository/location_repository.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/cubit/map_search_cubit.dart';
import 'package:where_to_fly/theme/app_snack_bar.dart';

/// Inline map message below the search bar (location errors, bounds warnings).
class MapTransientMessage extends StatefulWidget {
  const MapTransientMessage({
    required this.locationFailure,
    required this.outsideArgentina,
    super.key,
  });

  final LocationFailure? locationFailure;
  final bool outsideArgentina;

  @override
  State<MapTransientMessage> createState() => _MapTransientMessageState();
}

class _MapTransientMessageState extends State<MapTransientMessage> {
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _scheduleAutoDismiss();
  }

  @override
  void didUpdateWidget(MapTransientMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationFailure != widget.locationFailure ||
        oldWidget.outsideArgentina != widget.outsideArgentina) {
      _scheduleAutoDismiss();
    }
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    super.dispose();
  }

  void _scheduleAutoDismiss() {
    _autoDismiss?.cancel();
    _autoDismiss = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    context.read<MapSearchCubit>().clearLocationMessages();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String? message;
    final AppSnackBarIntent intent;
    final failure = widget.locationFailure;
    if (failure != null) {
      message = _locationErrorMessage(l10n, failure);
      intent = AppSnackBarIntent.error;
    } else if (widget.outsideArgentina) {
      message = l10n.outsideArgentina;
      intent = AppSnackBarIntent.warning;
    } else {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final style = AppSnackBar.styleFor(intent, theme.colorScheme);

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(14),
      color: style.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(style.icon, size: 22, color: style.foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: style.foreground,
                  height: 1.35,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: style.foreground),
              onPressed: _dismiss,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  static String _locationErrorMessage(
    AppLocalizations l10n,
    LocationFailure reason,
  ) {
    return switch (reason) {
      LocationFailure.serviceDisabled => l10n.locationServiceDisabled,
      LocationFailure.permissionDenied => l10n.locationPermissionDenied,
      LocationFailure.permissionDeniedForever =>
        l10n.locationPermissionDeniedForever,
      LocationFailure.unavailable => l10n.locationUnavailable,
    };
  }
}
