/// Parses OpenAIP / OpenAIR vertical limit objects into meters for zone checks.
///
/// Limits may be referenced to ground (AGL) or mean sea level (MSL). Without
/// terrain elevation, MSL limits are compared using `flightAgl + groundMsl`.
class OpenAipAltitudeLimits {
  const OpenAipAltitudeLimits({
    this.lowerMetersAgl,
    this.upperMetersAgl,
    this.lowerMetersMsl,
    this.upperMetersMsl,
  });

  factory OpenAipAltitudeLimits.fromAirspaceJson(Map<String, dynamic> item) {
    final lower = _parseLimit(
      item['lowerCeiling'] ?? item['lowerLimit'] ?? item['lower'],
    );
    final upper = _parseLimit(
      item['upperCeiling'] ?? item['upperLimit'] ?? item['upper'],
    );

    return OpenAipAltitudeLimits(
      lowerMetersAgl: lower?.aglMeters,
      upperMetersAgl: upper?.aglMeters,
      lowerMetersMsl: lower?.mslMeters,
      upperMetersMsl: upper?.mslMeters,
    );
  }

  final double? lowerMetersAgl;
  final double? upperMetersAgl;
  final double? lowerMetersMsl;
  final double? upperMetersMsl;

  bool get hasParsedLimits =>
      lowerMetersAgl != null ||
      upperMetersAgl != null ||
      lowerMetersMsl != null ||
      upperMetersMsl != null;

  /// Human-readable vertical limits for zone detail UI.
  String describe() {
    final lower = _describeBound(
      aglMeters: lowerMetersAgl,
      mslMeters: lowerMetersMsl,
      fallback: 'Surface',
    );
    final upper = _describeBound(
      aglMeters: upperMetersAgl,
      mslMeters: upperMetersMsl,
      fallback: 'Unlimited',
    );
    return '$lower – $upper';
  }

  static String _describeBound({
    required double? aglMeters,
    required double? mslMeters,
    required String fallback,
  }) {
    if (aglMeters != null) {
      if (aglMeters == 0) return 'GND';
      return '${_formatFeet(aglMeters)} ft AGL';
    }
    if (mslMeters != null) return '${_formatFeet(mslMeters)} ft MSL';
    return fallback;
  }

  static int _formatFeet(double meters) => (meters / 0.3048).round();
}

class _ParsedLimit {
  const _ParsedLimit({this.aglMeters, this.mslMeters});
  final double? aglMeters;
  final double? mslMeters;
}

_ParsedLimit? _parseLimit(Object? raw) {
  if (raw == null) return null;
  if (raw is String) return _parseLimitString(raw);
  if (raw is num) {
    return _ParsedLimit(aglMeters: _toMeters(raw.toDouble(), 'M'));
  }
  if (raw is! Map) return null;

  final map = raw.cast<String, dynamic>();
  final value = map['value'] ?? map['altitude'] ?? map['height'];
  if (value is String) return _parseLimitString(value, map);
  if (value == null) return null;

  final unit = _normalizeUnit(map['unit'] ?? map['uom'] ?? 'FT');
  final datum = _normalizeDatum(
    map['referenceDatum'] ?? map['reference'] ?? map['datum'] ?? 'GND',
  );

  final meters = value is num
      ? _toMeters(value.toDouble(), unit)
      : _parseLimitString(value.toString(), map)?.aglMeters;

  if (meters == null) return null;
  return _limitForDatum(meters, datum);
}

_ParsedLimit? _parseLimitString(
  String raw, [
  Map<String, dynamic>? parent,
]) {
  final text = raw.trim().toUpperCase();
  if (text.isEmpty) return null;
  if (text == 'GND' || text == 'SFC' || text == 'AGL' || text == 'GROUND') {
    return const _ParsedLimit(aglMeters: 0);
  }
  if (text == 'UNL' || text == 'UNLIMITED') return null;

  final match = RegExp(
    r'^(\d+(?:\.\d+)?)\s*(FT|FEET|M|MTR|METERS)?(?:\s*(AMSL|MSL|AGL|GND|SFC|STD))?$',
  ).firstMatch(text.replaceAll(' ', ''));
  if (match == null) return null;

  final value = double.parse(match.group(1)!);
  final unit = _normalizeUnit(match.group(2) ?? parent?['unit'] ?? 'FT');
  final datum = _normalizeDatum(
    match.group(3) ?? parent?['referenceDatum'] ?? 'GND',
  );
  return _limitForDatum(_toMeters(value, unit), datum);
}

String _normalizeUnit(Object? raw) {
  if (raw is num) {
    return switch (raw.toInt()) {
      0 => 'M',
      1 => 'FT',
      _ => raw.toString().toUpperCase(),
    };
  }
  return raw.toString().toUpperCase();
}

String _normalizeDatum(Object? raw) {
  if (raw is num) {
    return switch (raw.toInt()) {
      0 => 'GND',
      1 => 'MSL',
      _ => raw.toString().toUpperCase(),
    };
  }
  return raw.toString().toUpperCase();
}

_ParsedLimit _limitForDatum(double meters, String datum) {
  switch (datum) {
    case 'GND':
    case 'AGL':
    case 'SFC':
    case 'GROUND':
      return _ParsedLimit(aglMeters: meters);
    case 'MSL':
    case 'AMSL':
    case 'STD':
      return _ParsedLimit(mslMeters: meters);
    default:
      return _ParsedLimit(aglMeters: meters);
  }
}

double _toMeters(double value, String unit) {
  switch (unit) {
    case 'M':
    case 'MTR':
    case 'METER':
    case 'METERS':
      return value;
    case 'FT':
    case 'FEET':
    default:
      return value * 0.3048;
  }
}
