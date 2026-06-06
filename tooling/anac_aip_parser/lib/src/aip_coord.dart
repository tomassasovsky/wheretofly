/// A geographic coordinate parsed from the ANAC AIP DDMMSS format.
///
/// The AIP encodes coordinates as:
///   DDMMSS[NS]-DDDMMSS[EW]   e.g. `344927S-0583207W`
/// where DD/DDD = degrees, MM = minutes, SS = seconds.
class AipCoord {
  const AipCoord(this.lat, this.lon);

  final double lat;
  final double lon;

  // Matches a single coord anywhere in a string.
  static final _re =
      RegExp(r'(\d{2})(\d{2})(\d{2})([NS])-(\d{3})(\d{2})(\d{2})([EW])');

  static AipCoord parse(String raw) {
    final m = _re.firstMatch(raw.trim());
    if (m == null) throw FormatException('Not an AIP coordinate: "$raw"');
    return _fromMatch(m);
  }

  /// Returns all coordinates found in [text], in order.
  static List<AipCoord> allIn(String text) =>
      _re.allMatches(text).map(_fromMatch).toList();

  static AipCoord _fromMatch(RegExpMatch m) {
    final lat =
        _dms(m.group(1)!, m.group(2)!, m.group(3)!, m.group(4)! == 'S');
    final lon =
        _dms(m.group(5)!, m.group(6)!, m.group(7)!, m.group(8)! == 'W');
    return AipCoord(lat, lon);
  }

  static double _dms(String d, String min, String sec, bool negative) {
    final v = int.parse(d) + int.parse(min) / 60.0 + int.parse(sec) / 3600.0;
    return negative ? -v : v;
  }

  @override
  String toString() => '(${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
}
