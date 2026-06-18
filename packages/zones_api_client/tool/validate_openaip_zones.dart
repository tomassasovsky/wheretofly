// Compares OpenAIP Argentina export footprints against ANAC AIP polygons.
//
// Usage (from repo root):
//   dart run packages/zones_api_client/tool/validate_openaip_zones.dart \
//     --aip backend/data/anac_aip_zones.geojson
import 'dart:io';

import 'package:args/args.dart';
import 'package:zones_api_client/zones_api_client.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'aip',
      defaultsTo: 'backend/data/anac_aip_zones.geojson',
      help: 'Path to anac_aip_zones.geojson',
    );
  final options = parser.parse(args);

  final aipPath = options['aip'] as String;
  final openAip = await OpenAipExportZonesApiClient().fetchZones();
  final aip = await const AipGeoJsonReader().readFile(aipPath);
  final report = const OpenAipAipValidator().compare(
    openAipZones: openAip,
    aipZones: aip,
  );

  stdout.writeln('OpenAIP zones: ${openAip.length}');
  stdout.writeln('ANAC AIP zones: ${aip.length}');
  stdout.writeln('Matched pairs: ${report.comparisons.length}');
  stdout.writeln('Major mismatches: ${report.majorMismatches.length}');
  stdout.writeln('Review mismatches: ${report.reviewMismatches.length}');
  stdout.writeln('OpenAIP without AIP pair: ${report.unmatchedOpenAip.length}');
  stdout.writeln('AIP without OpenAIP pair: ${report.unmatchedAip.length}');
  stdout.writeln('');

  for (final comparison in report.comparisons) {
    stdout.writeln(
      '[${comparison.severity.name.toUpperCase()}] ${comparison.key}',
    );
    stdout.writeln('  OpenAIP: ${comparison.openAipName}');
    stdout.writeln('  AIP:     ${comparison.aipName}');
    stdout.writeln(
      '  area km² openAIP=${comparison.openAipAreaKm2.toStringAsFixed(1)} '
      'aip=${comparison.aipAreaKm2.toStringAsFixed(1)} '
      'ratio=${comparison.areaRatio?.toStringAsFixed(2) ?? 'n/a'}',
    );
    stdout.writeln(
      '  vertices openAIP=${comparison.openAipVertices} '
      'aip=${comparison.aipVertices}',
    );
    stdout.writeln(
      '  probe-only openAIP=${comparison.probePointsOnlyOpenAip} '
      'aip=${comparison.probePointsOnlyAip}',
    );
    stdout.writeln('');
  }

  if (report.majorMismatches.isNotEmpty) {
    stderr.writeln(
      'Found ${report.majorMismatches.length} major geometry mismatches.',
    );
    exitCode = 1;
  }
}
