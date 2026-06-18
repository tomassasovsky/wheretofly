import 'package:zones_api_client/src/text_encoding.dart';

/// Normalizes airspace names so OpenAIP and ANAC AIP zones can be paired.
abstract final class ZoneIdentity {
  static String? matchKey(String name) {
    final upper = repairUtf8Text(name).toUpperCase().trim();
    if (upper.isEmpty) return null;

    final sar = RegExp(r'\bSAR\s*0*(\d+)\b').firstMatch(upper);
    if (sar != null) {
      return 'sar_${int.parse(sar.group(1)!)}';
    }

    final tma = RegExp(r'\bTMA\s+([A-ZÁÉÍÓÚÑ0-9 ]+?)(?:\s+\d+)?\s*$')
        .firstMatch(upper.replaceAll('–', '-'));
    if (tma != null) {
      return 'tma_${_slug(tma.group(1)!)}';
    }

    final ctrSuffix = RegExp(r'^(.+?)\s+CTR\b').firstMatch(upper);
    if (ctrSuffix != null) {
      return 'ctr_${_slug(ctrSuffix.group(1)!)}';
    }

    final ctrPrefix = RegExp(r'\bCTR\s+(.+?)\s*$').firstMatch(upper);
    if (ctrPrefix != null) {
      return 'ctr_${_slug(ctrPrefix.group(1)!)}';
    }

    return null;
  }

  static String _slug(String raw) {
    final folded = raw
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ñ', 'N')
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return _aliases[folded] ?? folded.replaceAll(' ', '_');
  }

  static const _aliases = {
    'MINISTRO PISTARINI': 'EZEIZA',
    'JORGE NEWBERY': 'AEROPARQUE',
    'AEROPARQUE JORGE NEWBERY': 'AEROPARQUE',
    'CORDOBA': 'CORDOBA',
    'BAIRES': 'BAIRES',
    'BAIRES I': 'BAIRES',
    'BAIRES II': 'BAIRES',
  };
}
