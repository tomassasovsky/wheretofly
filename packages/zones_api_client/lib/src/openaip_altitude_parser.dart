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

  final unit = (map['unit'] ?? map['uom'] ?? 'FT').toString().toUpperCase();
  final datum =
      (map['referenceDatum'] ?? map['reference'] ?? map['datum'] ?? 'GND')
          .toString()
          .toUpperCase();

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
  final unit =
      (match.group(2) ?? parent?['unit']?.toString() ?? 'FT').toUpperCase();
  final datum =
      (match.group(3) ?? parent?['referenceDatum']?.toString() ?? 'GND')
          .toUpperCase();
  return _limitForDatum(_toMeters(value, unit), datum);
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
