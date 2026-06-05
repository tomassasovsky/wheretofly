import 'dart:typed_data';

/// Wind gust colorscale (matches `lib/map/wind/om/wind_color_scale.dart`).
abstract final class WindColorScale {
  static const breakpoints = [
    0.0,
    0.3,
    0.6,
    1.0,
    1.5,
    2.0,
    3.0,
    4.0,
    5.0,
    6.0,
    7.0,
    8.0,
    9.0,
    10.0,
    12.5,
    15.0,
    17.5,
    20.0,
    25.0,
    30.0,
    40.0,
    50.0,
    60.0,
  ];

  static const colors = <(int r, int g, int b, double a)>[
    (70, 130, 180, 0.0),
    (64, 137, 179, 0.1),
    (58, 144, 177, 0.143),
    (51, 155, 175, 0.2),
    (42, 169, 172, 0.267),
    (34, 167, 150, 0.333),
    (20, 157, 100, 0.467),
    (9, 144, 48, 0.6),
    (0, 128, 0, 0.733),
    (21, 142, 0, 0.867),
    (47, 156, 0, 1.0),
    (77, 170, 0, 1.0),
    (111, 184, 0, 1.0),
    (149, 199, 0, 1.0),
    (234, 204, 0, 1.0),
    (255, 153, 0, 1.0),
    (255, 124, 0, 1.0),
    (255, 94, 0, 1.0),
    (255, 32, 0, 1.0),
    (212, 0, 0, 1.0),
    (170, 0, 0, 1.0),
    (128, 0, 64, 1.0),
    (64, 0, 64, 1.0),
  ];

  static (int r, int g, int b, int a) colorFor(double mps) {
    if (!mps.isFinite) return _toBytes(colors.first);
    if (mps <= breakpoints.first) return _toBytes(colors.first);
    if (mps >= breakpoints.last) return _toBytes(colors.last);

    var lower = 0;
    while (lower + 1 < breakpoints.length && breakpoints[lower + 1] <= mps) {
      lower++;
    }
    final upper = lower + 1;
    final span = breakpoints[upper] - breakpoints[lower];
    final t = span > 0 ? (mps - breakpoints[lower]) / span : 0.0;
    final a = colors[lower];
    final b = colors[upper];
    return (
      _lerpInt(a.$1, b.$1, t),
      _lerpInt(a.$2, b.$2, t),
      _lerpInt(a.$3, b.$3, t),
      (255 * _lerp(a.$4, b.$4, t)).round(),
    );
  }

  // 512 entries cover 0–64 m/s at 0.125 m/s resolution (2 KB total).
  static const int _lutEntries = 512;
  static const double _lutMaxMps = 64.0;

  static final Uint8List _lut = _buildLut();

  static Uint8List _buildLut() {
    final buf = Uint8List(_lutEntries * 4);
    for (var i = 0; i < _lutEntries; i++) {
      final mps = i * _lutMaxMps / _lutEntries;
      final (r, g, b, a) = colorFor(mps);
      buf[i * 4]     = r;
      buf[i * 4 + 1] = g;
      buf[i * 4 + 2] = b;
      buf[i * 4 + 3] = a;
    }
    return buf;
  }

  /// Writes the RGBA color for [mps] into [pixels] at [offset] using a
  /// precomputed lookup table — O(1) vs the O(n) linear scan in [colorFor].
  static void writePixel(Uint8List pixels, int offset, double mps) {
    if (!mps.isFinite) {
      pixels[offset]     = 0;
      pixels[offset + 1] = 0;
      pixels[offset + 2] = 0;
      pixels[offset + 3] = 0;
      return;
    }
    final i =
        (mps * (_lutEntries / _lutMaxMps)).toInt().clamp(0, _lutEntries - 1) *
            4;
    pixels[offset]     = _lut[i];
    pixels[offset + 1] = _lut[i + 1];
    pixels[offset + 2] = _lut[i + 2];
    pixels[offset + 3] = _lut[i + 3];
  }

  static (int r, int g, int b, int a) _toBytes((int, int, int, double) c) =>
      (c.$1, c.$2, c.$3, (c.$4 * 255).round());

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static int _lerpInt(int a, int b, double t) =>
      _lerp(a.toDouble(), b.toDouble(), t).round();
}
