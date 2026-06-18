import 'dart:math' as math;

import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/zone_source_ids.dart';

/// A NOTAM row whose geometry could not be derived (no coordinates, or only a
/// reference to a named airway/TMA). Surfaced as a list entry rather than
/// silently dropped, so a human can review it.
class UngeocodableNotam {
  const UngeocodableNotam({required this.id, required this.summary});

  /// NOTAM series id, e.g. `A1009/2026`.
  final String id;

  /// The English NOTAM body, trimmed for review.
  final String summary;
}

/// Result of parsing a NOTAM HTML table: drawable [zones] plus the
/// [ungeocodable] NOTAMs that need manual review.
class NotamParseResult {
  const NotamParseResult({required this.zones, required this.ungeocodable});

  final List<ZoneData> zones;
  final List<UngeocodableNotam> ungeocodable;
}

/// Parses the EANA NOTAM `POST /notam/pib` HTML table into [ZoneData].
///
/// Each row carries a NOTAM id, a pre-extracted `Desde:`/`Hasta:` validity
/// window, and a free-text body with geometry as `COORD GEO <DMS>/<DMS> ...`
/// (a polygon when dash/comma-separated, a circle when followed by `RDO <n>NM`)
/// and vertical limits (`F) GND G) 400FT AGL`, `GND FL120`). The body text is
/// noisy, so parsing is tolerant and anything un-geocodable is listed, never
/// dropped (see [NotamParseResult.ungeocodable]).
abstract final class NotamParser {
  static const _ftToMeters = 0.3048;
  static const _nmToMeters = 1852.0;

  static NotamParseResult parse(String html) {
    final zones = <ZoneData>[];
    final ungeocodable = <UngeocodableNotam>[];

    for (final row in _rows(html)) {
      final id = _firstParagraph(row, 'place');
      final info = _cell(row, 'info');
      if (id == null || info == null) continue;

      final paragraphs = _paragraphs(info);
      final from = _validity(paragraphs, 'Desde:');
      final to = _validity(paragraphs, 'Hasta:');
      final body = _englishBody(paragraphs);
      if (body.isEmpty) continue;

      final coords = _coords(body);
      final radius = _radioMeters(body);
      final limits = _verticalLimits(body);

      if (coords.length >= 3) {
        zones.add(
          _polygonZone(id, body, coords, limits, from: from, to: to),
        );
      } else if (coords.length == 1 && radius != null) {
        zones.add(
          _circleZone(
            id,
            body,
            coords.single,
            radius,
            limits,
            from: from,
            to: to,
          ),
        );
      } else {
        ungeocodable.add(UngeocodableNotam(id: id, summary: body));
      }
    }

    return NotamParseResult(zones: zones, ungeocodable: ungeocodable);
  }

  // --- HTML extraction -------------------------------------------------------

  static Iterable<String> _rows(String html) =>
      RegExp(r'<tr\b.*?</tr>', dotAll: true)
          .allMatches(html)
          .map((m) => m.group(0)!);

  static String? _cell(String row, String id) =>
      RegExp('<td[^>]*id="$id"[^>]*>(.*?)</td>', dotAll: true)
          .firstMatch(row)
          ?.group(1);

  static List<String> _paragraphs(String cell) => RegExp(
        r'<p\b[^>]*>(.*?)</p>',
        dotAll: true,
      ).allMatches(cell).map((m) => _text(m.group(1)!)).toList();

  static String? _firstParagraph(String row, String cellId) {
    final cell = _cell(row, cellId);
    if (cell == null) return null;
    final paragraphs = _paragraphs(cell);
    return paragraphs.isEmpty || paragraphs.first.isEmpty
        ? null
        : paragraphs.first;
  }

  /// English body: the paragraph carrying the NOTAM text, truncated at the
  /// `Versión en Español:` marker that precedes the Spanish duplicate.
  static String _englishBody(List<String> paragraphs) {
    for (final p in paragraphs) {
      if (p.startsWith('Desde:') || p.startsWith('Hasta:')) continue;
      final marker = p.indexOf('Versión en Español');
      return (marker >= 0 ? p.substring(0, marker) : p).trim();
    }
    return '';
  }

  static DateTime? _validity(List<String> paragraphs, String label) {
    for (final p in paragraphs) {
      if (!p.startsWith(label)) continue;
      final raw = p.substring(label.length).trim();
      // EANA prints NOTAM B)/C) times, which are UTC by ICAO convention.
      final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
      return parsed == null
          ? null
          : DateTime.utc(
              parsed.year,
              parsed.month,
              parsed.day,
              parsed.hour,
              parsed.minute,
              parsed.second,
            );
    }
    return null;
  }

  static String _text(String html) => html
      .replaceAll(RegExp('<[^>]+>'), ' ')
      .replaceAll('&oacute;', 'ó')
      .replaceAll('&aacute;', 'á')
      .replaceAll('&eacute;', 'é')
      .replaceAll('&iacute;', 'í')
      .replaceAll('&uacute;', 'ú')
      .replaceAll('&ntilde;', 'ñ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // --- Geometry --------------------------------------------------------------

  /// Coordinate pairs as `[lon, lat]` (GeoJSON order), in document order.
  /// Latitude is `DDMMSS[NS]`, longitude `DDDMMSS[EW]`; the literal `COORD GEO`
  /// label may be absent or run together (`COORDGEO`).
  static List<List<double>> _coords(String body) {
    final matches =
        RegExp(r'(\d{6})\s*([NS])\s*/\s*(\d{7})\s*([EW])').allMatches(body);
    return [
      for (final m in matches)
        [
          _dms(m.group(3)!, m.group(4)!, degDigits: 3),
          _dms(m.group(1)!, m.group(2)!, degDigits: 2),
        ],
    ];
  }

  static double _dms(
    String digits,
    String hemisphere, {
    required int degDigits,
  }) {
    final deg = int.parse(digits.substring(0, degDigits));
    final min = int.parse(digits.substring(degDigits, degDigits + 2));
    final sec = int.parse(digits.substring(degDigits + 2, degDigits + 4));
    final value = deg + min / 60 + sec / 3600;
    return (hemisphere == 'S' || hemisphere == 'W') ? -value : value;
  }

  static double? _radioMeters(String body) {
    final m = RegExp(r'RDO\s*(\d+(?:\.\d+)?)\s*NM').firstMatch(body);
    return m == null ? null : double.parse(m.group(1)!) * _nmToMeters;
  }

  static ZoneData _polygonZone(
    String id,
    String body,
    List<List<double>> ring,
    _VerticalLimits limits, {
    DateTime? from,
    DateTime? to,
  }) {
    final lon = ring.map((p) => p[0]).reduce((a, b) => a + b) / ring.length;
    final lat = ring.map((p) => p[1]).reduce((a, b) => a + b) / ring.length;
    final maxDistance =
        ring.map((p) => _haversine(lat, lon, p[1], p[0])).reduce(math.max);
    final radius = maxDistance < 500 ? 500.0 : maxDistance;
    return _zone(id, body, lat, lon, radius, limits, ring, from, to);
  }

  static ZoneData _circleZone(
    String id,
    String body,
    List<double> center,
    double radius,
    _VerticalLimits limits, {
    DateTime? from,
    DateTime? to,
  }) =>
      _zone(id, body, center[1], center[0], radius, limits, null, from, to);

  static ZoneData _zone(
    String id,
    String body,
    double lat,
    double lon,
    double radius,
    _VerticalLimits limits,
    List<List<double>>? polygon,
    DateTime? from,
    DateTime? to,
  ) =>
      ZoneData(
        id: 'notam_${id.replaceAll(RegExp('[^A-Za-z0-9]'), '_')}',
        name: 'NOTAM $id',
        categoryId: 'restricted',
        latitude: lat,
        longitude: lon,
        radiusMeters: radius,
        polygon: polygon,
        allowedPermissionIds: const {},
        details: body,
        lowerLimitMetersAgl: limits.lowerAgl,
        upperLimitMetersAgl: limits.upperAgl,
        lowerLimitMetersMsl: limits.lowerMsl,
        upperLimitMetersMsl: limits.upperMsl,
        source: ZoneSourceIds.notam,
        activeFrom: from,
        activeTo: to,
      );

  // --- Vertical limits -------------------------------------------------------

  /// Parses the lower/upper extent. Tokens, in order, are the lower then upper
  /// limit: `GND`/`SFC` → ground (0 AGL), `<n>FT AGL` → metres AGL, `<n>FT`
  /// (AMSL implied) and `FL<n>` → metres MSL.
  static _VerticalLimits _verticalLimits(String body) {
    final tokens = RegExp(
      r'GND|SFC|FL\s*\d+|\d+\s*FT(?:\s*(?:AGL|AMSL|MSL))?',
      caseSensitive: false,
    ).allMatches(body).map((m) => m.group(0)!).toList();
    if (tokens.isEmpty) return const _VerticalLimits();

    final lower = _altitude(tokens.first);
    final upper = tokens.length > 1 ? _altitude(tokens[1]) : null;
    return _VerticalLimits(lower: lower, upper: upper);
  }

  static _Altitude _altitude(String token) {
    final t = token.toUpperCase().replaceAll(' ', '');
    if (t == 'GND' || t == 'SFC') return const _Altitude(meters: 0, agl: true);
    final fl = RegExp(r'FL(\d+)').firstMatch(t);
    if (fl != null) {
      return _Altitude(meters: int.parse(fl.group(1)!) * 100 * _ftToMeters);
    }
    final ft = RegExp(r'(\d+)FT(AGL|AMSL|MSL)?').firstMatch(t);
    if (ft != null) {
      return _Altitude(
        meters: int.parse(ft.group(1)!) * _ftToMeters,
        agl: ft.group(2) == 'AGL',
      );
    }
    return const _Altitude(meters: 0, agl: true);
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.asin(math.min(1, math.sqrt(a)));
  }
}

class _Altitude {
  const _Altitude({required this.meters, this.agl = false});
  final double meters;
  final bool agl;
}

class _VerticalLimits {
  const _VerticalLimits({_Altitude? lower, _Altitude? upper})
      : _lower = lower,
        _upper = upper;

  final _Altitude? _lower;
  final _Altitude? _upper;

  double? get lowerAgl => _aglMeters(_lower);
  double? get upperAgl => _aglMeters(_upper);
  double? get lowerMsl => _mslMeters(_lower);
  double? get upperMsl => _mslMeters(_upper);

  static double? _aglMeters(_Altitude? a) =>
      a != null && a.agl ? a.meters : null;
  static double? _mslMeters(_Altitude? a) =>
      a != null && !a.agl ? a.meters : null;
}
