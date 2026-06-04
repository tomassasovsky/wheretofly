import 'package:flutter/material.dart';

/// Open-Meteo `wind` breakpoint colorscale (used for `wind_gusts_10m`).
///
/// Values from `@openmeteo/weather-map-layer` — keep in sync with
/// Open-Meteo weather-map-layer (wind palette).
abstract final class WindColorscale {
  static const unit = 'm/s';

  static const breakpoints = <double>[
    0,
    0.3,
    0.6,
    1,
    1.5,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    12.5,
    15,
    17.5,
    20,
    25,
    30,
    40,
    50,
    60,
  ];

  /// RGBA tuples from the weather-map-layer; legend uses full opacity.
  static const _rgba = <List<double>>[
    [70, 130, 180, 0],
    [64, 137, 179, 0.1],
    [58, 144, 177, 0.143],
    [51, 155, 175, 0.2],
    [42, 169, 172, 0.267],
    [34, 167, 150, 0.333],
    [20, 157, 100, 0.467],
    [9, 144, 48, 0.6],
    [0, 128, 0, 0.733],
    [21, 142, 0, 0.867],
    [47, 156, 0, 1],
    [77, 170, 0, 1],
    [111, 184, 0, 1],
    [149, 199, 0, 1],
    [234, 204, 0, 1],
    [255, 153, 0, 1],
    [255, 124, 0, 1],
    [255, 94, 0, 1],
    [255, 35, 0, 1],
    [240, 0, 28, 1],
    [165, 0, 117, 1],
    [124, 2, 83, 1],
    [116, 5, 5, 1],
  ];

  static final maxValue = breakpoints.last;

  static List<Color> get legendColors => [
        for (final band in _rgba)
          Color.fromRGBO(
            band[0].round(),
            band[1].round(),
            band[2].round(),
            1,
          ),
      ];

  static List<double> get gradientStops => [
        for (final value in breakpoints) value / maxValue,
      ];

  /// Tick labels shown under the gradient bar.
  static const tickValues = <double>[0, 10, 20, 30, 40, 60];
}
