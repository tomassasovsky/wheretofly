import 'dart:ui';

/// Wind gust colorscale (`wind` alias for `wind_gusts_10m`).
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

  static const colors = <Color>[
    Color.fromRGBO(70, 130, 180, 0),
    Color.fromRGBO(64, 137, 179, 0.1),
    Color.fromRGBO(58, 144, 177, 0.143),
    Color.fromRGBO(51, 155, 175, 0.2),
    Color.fromRGBO(42, 169, 172, 0.267),
    Color.fromRGBO(34, 167, 150, 0.333),
    Color.fromRGBO(20, 157, 100, 0.467),
    Color.fromRGBO(9, 144, 48, 0.6),
    Color.fromRGBO(0, 128, 0, 0.733),
    Color.fromRGBO(21, 142, 0, 0.867),
    Color.fromRGBO(47, 156, 0, 1),
    Color.fromRGBO(77, 170, 0, 1),
    Color.fromRGBO(111, 184, 0, 1),
    Color.fromRGBO(149, 199, 0, 1),
    Color.fromRGBO(234, 204, 0, 1),
    Color.fromRGBO(255, 153, 0, 1),
    Color.fromRGBO(255, 124, 0, 1),
    Color.fromRGBO(255, 94, 0, 1),
    Color.fromRGBO(255, 32, 0, 1),
    Color.fromRGBO(212, 0, 0, 1),
    Color.fromRGBO(170, 0, 0, 1),
    Color.fromRGBO(128, 0, 64, 1),
    Color.fromRGBO(64, 0, 64, 1),
  ];

  static Color colorFor(double mps) {
    if (!mps.isFinite) return colors.first;
    if (mps <= breakpoints.first) return colors.first;
    if (mps >= breakpoints.last) return colors.last;

    var lower = 0;
    while (lower + 1 < breakpoints.length && breakpoints[lower + 1] <= mps) {
      lower++;
    }
    final upper = lower + 1;
    final span = breakpoints[upper] - breakpoints[lower];
    final t = span > 0 ? (mps - breakpoints[lower]) / span : 0.0;
    return Color.lerp(colors[lower], colors[upper], t)!;
  }
}
