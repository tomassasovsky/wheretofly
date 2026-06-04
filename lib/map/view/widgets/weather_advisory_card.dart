import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/theme/app_snack_bar.dart';
import 'package:where_to_fly/weather/weather_alerts_cubit.dart';

/// Compact weather advisory shown alongside zone verdicts.
class WeatherAdvisoryCard extends StatelessWidget {
  const WeatherAdvisoryCard({
    required this.snapshot,
    this.showSaveAlert = false,
    super.key,
  });

  final WeatherSnapshot snapshot;
  final bool showSaveAlert;

  String? _reasonText(AppLocalizations l10n) {
    if (snapshot.advisoryReasons.isEmpty) return null;
    switch (snapshot.advisoryReasons.first) {
      case 'smnAlert':
        return l10n.weatherReasonSmnAlert;
      case 'windHigh':
        return l10n.weatherReasonWindHigh;
      case 'windElevated':
        return l10n.weatherReasonWindElevated;
      case 'windModerate':
        return l10n.weatherReasonWindModerate;
      case 'favorable':
        return l10n.weatherReasonFavorable;
    }
    return null;
  }

  Color _color(BuildContext context) {
    switch (snapshot.advisoryLevel) {
      case WeatherAdvisoryLevel.good:
        return const Color(0xFF2E7D32);
      case WeatherAdvisoryLevel.caution:
        return const Color(0xFFF9A825);
      case WeatherAdvisoryLevel.highCaution:
        return const Color(0xFFEF6C00);
      case WeatherAdvisoryLevel.notRecommended:
        return const Color(0xFFD32F2F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final wind = snapshot.windSpeedMs;
    final gust = snapshot.windGustMs;
    final reasonText = _reasonText(l10n);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color(context).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weatherAdvisoryTitle,
            style: theme.textTheme.titleSmall?.copyWith(color: _color(context)),
          ),
          if (wind != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.weatherWind(
                wind.toStringAsFixed(1),
                gust?.toStringAsFixed(1) ?? '—',
              ),
            ),
          ],
          if (reasonText != null) ...[
            const SizedBox(height: 4),
            Text(
              reasonText,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Text(l10n.weatherDisclaimer, style: theme.textTheme.labelSmall),
          if (showSaveAlert) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _saveAlert(context),
              icon: const Icon(Icons.notifications_outlined, size: 18),
              label: Text(l10n.weatherAlertSave),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveAlert(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final lat = snapshot.lat.toStringAsFixed(3);
    final lon = snapshot.lon.toStringAsFixed(3);
    final defaultLabel = '$lat, $lon';
    final label = await showDialog<String>(
      context: context,
      builder: (context) => _WeatherAlertLabelDialog(
        title: l10n.weatherAlertSave,
        labelHint: l10n.weatherAlertLabel,
        cancelLabel: l10n.cancel,
        confirmLabel: l10n.done,
        initialLabel: defaultLabel,
      ),
    );
    if (label == null || label.trim().isEmpty || !context.mounted) return;

    final ok = await context.read<WeatherAlertsCubit>().save(
          label: label.trim(),
          point: LatLng(snapshot.lat, snapshot.lon),
        );
    if (!context.mounted) return;
    context.showAppSnackBar(
      ok ? l10n.weatherAlertSaved : l10n.weatherFetchFailed,
      intent: ok ? AppSnackBarIntent.success : AppSnackBarIntent.error,
    );
  }
}

/// Dialog that owns its [TextEditingController] lifecycle.
class _WeatherAlertLabelDialog extends StatefulWidget {
  const _WeatherAlertLabelDialog({
    required this.title,
    required this.labelHint,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.initialLabel,
  });

  final String title;
  final String labelHint;
  final String cancelLabel;
  final String confirmLabel;
  final String initialLabel;

  @override
  State<_WeatherAlertLabelDialog> createState() =>
      _WeatherAlertLabelDialogState();
}

class _WeatherAlertLabelDialogState extends State<_WeatherAlertLabelDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: widget.labelHint),
        autofocus: true,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
