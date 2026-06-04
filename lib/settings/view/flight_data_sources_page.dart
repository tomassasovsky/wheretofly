import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/theme/app_snack_bar.dart';

/// Official and project URLs referenced on [FlightDataSourcesPage].
abstract final class FlightDataSourceUrls {
  static const madhel = 'https://datos.anac.gob.ar/madhel/';
  static const openAip = 'https://www.openaip.net/';
  static const anacDrones =
      'https://www.argentina.gob.ar/anac/nuevo-marco-normativo-para-la-operacion-de-drones';
  static const openMeteo = 'https://open-meteo.com/';
  static const smn = 'https://www.smn.gob.ar/';
  static const osm = 'https://www.openstreetmap.org/copyright';
}

/// Explains where fly/no-fly guidance, zone geometry, and related map data come from.
class FlightDataSourcesPage extends StatelessWidget {
  const FlightDataSourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.flightDataSourcesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.flightDataSourcesIntro,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FlightDataSourcesSection(
            title: l10n.flightDataSourcesHowWeDecideTitle,
            body: l10n.flightDataSourcesHowWeDecideBody,
          ),
          _FlightDataSourcesSection(
            title: l10n.flightDataSourcesPermissionsTitle,
            body: l10n.flightDataSourcesPermissionsBody,
            linkLabel: l10n.flightDataSourcesOpenLink,
            url: FlightDataSourceUrls.anacDrones,
          ),
          _FlightDataSourcesSection(title: l10n.flightDataSourcesZonesTitle),
          _FlightDataSourceTile(
            title: l10n.flightDataSourcesZoneMadhelTitle,
            body: l10n.flightDataSourcesZoneMadhelBody,
            linkLabel: l10n.flightDataSourcesOpenLink,
            url: FlightDataSourceUrls.madhel,
          ),
          _FlightDataSourceTile(
            title: l10n.flightDataSourcesZoneOpenAipTitle,
            body: l10n.flightDataSourcesZoneOpenAipBody,
            linkLabel: l10n.flightDataSourcesOpenLink,
            url: FlightDataSourceUrls.openAip,
          ),
          _FlightDataSourceTile(
            title: l10n.flightDataSourcesZoneCuratedTitle,
            body: l10n.flightDataSourcesZoneCuratedBody,
          ),
          _FlightDataSourceTile(
            title: l10n.flightDataSourcesZoneFeedTitle,
            body: l10n.flightDataSourcesZoneFeedBody,
          ),
          const SizedBox(height: 8),
          _FlightDataSourcesSection(
            title: l10n.flightDataSourcesSearchTitle,
            body: l10n.flightDataSourcesSearchBody,
            linkLabel: l10n.flightDataSourcesOpenLink,
            url: FlightDataSourceUrls.osm,
          ),
          _FlightDataSourcesSection(
            title: l10n.flightDataSourcesWeatherTitle,
            body: l10n.flightDataSourcesWeatherBody,
          ),
          _FlightDataSourceTile(
            title: l10n.flightDataSourcesWeatherOpenMeteoTitle,
            body: l10n.flightDataSourcesWeatherOpenMeteoBody,
            linkLabel: l10n.flightDataSourcesOpenLink,
            url: FlightDataSourceUrls.openMeteo,
          ),
          _FlightDataSourceTile(
            title: l10n.flightDataSourcesWeatherSmnTitle,
            body: l10n.flightDataSourcesWeatherSmnBody,
            linkLabel: l10n.flightDataSourcesOpenLink,
            url: FlightDataSourceUrls.smn,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.flightDataSourcesDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightDataSourcesSection extends StatelessWidget {
  const _FlightDataSourcesSection({
    required this.title,
    this.body,
    this.linkLabel,
    this.url,
  });

  final String title;
  final String? body;
  final String? linkLabel;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body!, style: theme.textTheme.bodyMedium),
          ],
          if (url != null && linkLabel != null) ...[
            const SizedBox(height: 4),
            _FlightDataSourceLinkButton(label: linkLabel!, url: url!),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _FlightDataSourceTile extends StatelessWidget {
  const _FlightDataSourceTile({
    required this.title,
    required this.body,
    this.linkLabel,
    this.url,
  });

  final String title;
  final String body;
  final String? linkLabel;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
          if (url != null && linkLabel != null)
            _FlightDataSourceLinkButton(label: linkLabel!, url: url!),
        ],
      ),
    );
  }
}

class _FlightDataSourceLinkButton extends StatelessWidget {
  const _FlightDataSourceLinkButton({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => _openUrl(context, url),
        child: Text(label),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      context.showAppSnackBar(
        AppLocalizations.of(context).couldNotOpen(url),
        intent: AppSnackBarIntent.error,
      );
    }
  }
}
