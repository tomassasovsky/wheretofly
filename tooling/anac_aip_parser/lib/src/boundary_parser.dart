import 'aip_coord.dart';
import 'aip_segment.dart';

/// Parses ANAC Argentina AIP lateral-limits boundary text into a structured
/// segment list.
///
/// The AIP uses Spanish prose with three element types:
///
///   1. **Coordinate** `DDMMSS[NS]-DDDMMSS[EW]` — a vertex to connect with a
///      straight geodesic from the previous point.
///
///   2. **Arc** — introduced by "siguiendo un arco de X NM de radio con
///      centro en …" (or the DME variant "siguiendo un arco de X NM DME …").
///      The arc end is specified with "hasta COORD". Direction is either
///      explicit ("en sentido horario/antihorario") or hinted ("hacia el Sur").
///
///   3. **Full circle** — introduced by "siguiendo una circunferencia de X NM
///      de radio con centro en …". Produces a [CircleSegment].
///
/// The first coordinate in the text is the boundary start; the segment list
/// encodes all subsequent points.
class BoundaryParser {
  // ---- coord ----------------------------------------------------------------

  static final _coordRe =
      RegExp(r'(\d{2})(\d{2})(\d{2})([NS])-(\d{3})(\d{2})(\d{2})([EW])');

  // ---- arc: "siguiendo un arco de X NM de radio con centro en … (COORD)" ---

  // Matches the radius number after "arco de".
  static final _arcRadiusRe = RegExp(
    r'arco de\s+(\d+(?:[.,]\d+)?)\s+NM',
    caseSensitive: false,
  );

  // Matches the centre coord in parentheses: "(344927S-0583207W)".
  // Also handles the DME variant where the coord appears in parentheses after
  // the navaid name.
  static final _arcCentreRe = RegExp(
    r'\(\s*(\d{6}[NS]-\d{7}[EW])\s*\)',
  );

  // "en sentido horario" or "en sentido antihorario / contrario al reloj"
  static final _cwRe = RegExp(
    r'en sentido (horario|antihorario|contrario)',
    caseSensitive: false,
  );

  // "hacia el Norte/Sur/Este/Oeste/NE/NO/SE/SO"
  static final _towardRe = RegExp(
    r'hacia el?\s+(Norte|Sur|Este|Oeste|NE|NO|SE|SO|NNE|NNO|SSE|SSO|ENE|ESE|ONO|OSO)',
    caseSensitive: false,
  );

  // "hasta COORD" — arc end point
  static final _hastaRe = RegExp(
    r'hasta\s+(\d{6}[NS]-\d{7}[EW])',
    caseSensitive: false,
  );

  // ---- full circle: "siguiendo una circunferencia de X NM …" ---------------
  static final _circleRe = RegExp(
    r'circunferencia de\s+(\d+(?:[.,]\d+)?)\s+NM',
    caseSensitive: false,
  );

  /// Parses [text] and returns `(start, segments)`.
  ///
  /// Returns `null` if no coordinates are found.
  (AipCoord, List<AipSegment>)? parse(String text) {
    // Normalise whitespace.
    final normalised = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Find all coord positions (used to split the text into chunks).
    final allMatches = _coordRe.allMatches(normalised).toList();
    if (allMatches.isEmpty) return null;

    final start = _coordFrom(allMatches.first);
    final segments = <AipSegment>[];
    var pos = allMatches.first.end;

    for (var i = 1; i < allMatches.length; i++) {
      final matchEnd = allMatches[i].end;
      final coordEnd = allMatches[i].end;
      // Text chunk between previous coord and this one.
      final chunk = normalised.substring(pos, coordEnd);
      final thisCoord = _coordFrom(allMatches[i]);

      if (_circleRe.hasMatch(chunk)) {
        // Full circle — collect centre and radius from this chunk.
        final radius = _parseRadius(chunk, _circleRe);
        final centre = _parseCentre(chunk) ?? thisCoord;
        segments.add(CircleSegment(center: centre, radiusNm: radius));
        pos = coordEnd;
        continue;
      }

      if (_arcRadiusRe.hasMatch(chunk)) {
        // Arc segment — the "hasta COORD" end point may be the current coord
        // or a later one.  Grab it from the hasta clause if present; otherwise
        // use thisCoord.
        final radius = _parseRadius(chunk, _arcRadiusRe);
        final centre = _parseCentre(chunk);
        if (centre == null) {
          // Malformed arc — fall back to a straight segment.
          segments.add(StraightSegment(thisCoord));
          pos = coordEnd;
          continue;
        }

        AipCoord endCoord = thisCoord;
        // Check if hasta falls on a LATER coord in the text.
        final hastaM = _hastaRe.firstMatch(chunk);
        if (hastaM != null) {
          endCoord = AipCoord.parse(hastaM.group(1)!);
          // Advance i past any coords consumed by the hasta clause.
          while (i + 1 < allMatches.length) {
            final next = _coordFrom(allMatches[i + 1]);
            if (_approxEqual(next, endCoord)) {
              i++;
              pos = allMatches[i].end;
              break;
            }
            i++;
          }
        }

        bool? cw = _parseCw(chunk);
        String? hint = _parseHint(chunk);
        segments.add(ArcSegment(
          center: centre,
          radiusNm: radius,
          to: endCoord,
          clockwise: cw,
          directionHint: hint,
        ));
        pos = allMatches[i].end;
        continue;
      }

      // Plain straight segment.
      segments.add(StraightSegment(thisCoord));
      pos = coordEnd;
    }

    return (start, segments);
  }

  static AipCoord _coordFrom(RegExpMatch m) => AipCoord(
        _dms(m.group(1)!, m.group(2)!, m.group(3)!, m.group(4)! == 'S'),
        _dms(m.group(5)!, m.group(6)!, m.group(7)!, m.group(8)! == 'W'),
      );

  static double _dms(String d, String min, String sec, bool neg) {
    final v = int.parse(d) + int.parse(min) / 60.0 + int.parse(sec) / 3600.0;
    return neg ? -v : v;
  }

  static double _parseRadius(String chunk, RegExp re) {
    final m = re.firstMatch(chunk);
    if (m == null) return 0;
    return double.parse(m.group(1)!.replaceAll(',', '.'));
  }

  static AipCoord? _parseCentre(String chunk) {
    final m = _arcCentreRe.firstMatch(chunk);
    if (m == null) return null;
    return AipCoord.parse(m.group(1)!);
  }

  static bool? _parseCw(String chunk) {
    final m = _cwRe.firstMatch(chunk);
    if (m == null) return null;
    final word = m.group(1)!.toLowerCase();
    // "horario" = clockwise; "antihorario"/"contrario" = counter-clockwise
    return word == 'horario';
  }

  static String? _parseHint(String chunk) {
    final m = _towardRe.firstMatch(chunk);
    return m?.group(1);
  }

  static bool _approxEqual(AipCoord a, AipCoord b) =>
      (a.lat - b.lat).abs() < 1e-4 && (a.lon - b.lon).abs() < 1e-4;
}
