import 'package:flutter/material.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/view/widgets/map_zoom_controls.dart';

/// Right-side FAB column: legend, zoom, locate.
class MapFabColumn extends StatelessWidget {
  const MapFabColumn({
    required this.locating,
    required this.onToggleLegend,
    required this.onLocate,
    required this.onZoomIn,
    required this.onZoomOut,
    super.key,
  });

  final bool locating;
  final VoidCallback onToggleLegend;
  final VoidCallback onLocate;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'legend',
          onPressed: onToggleLegend,
          tooltip: l10n.permissionsAndResources,
          child: const Icon(Icons.layers_outlined),
        ),
        const SizedBox(height: 12),
        MapZoomControls(onZoomIn: onZoomIn, onZoomOut: onZoomOut),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'locate',
          onPressed: locating ? null : onLocate,
          tooltip: l10n.locateMe,
          child: locating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
        ),
      ],
    );
  }
}
