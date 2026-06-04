/// Simplified neighbor-country outlines used only for the inclusive fallback
/// (Natural Earth paths can miss slivers of Argentine territory).
abstract final class NeighborExclusions {
  static const uruguay = <(double lat, double lon)>[
    (-30.08, -57.73),
    (-31.55, -58.18),
    (-33.70, -58.42),
    (-34.72, -57.88),
    (-34.98, -56.72),
    (-35.05, -55.15),
    (-34.68, -53.62),
    (-33.72, -53.32),
    (-32.30, -53.12),
    (-31.05, -54.45),
    (-30.18, -57.05),
  ];

  static const paraguay = <(double lat, double lon)>[
    (-22.05, -62.65),
    (-22.10, -57.55),
    (-27.55, -55.85),
    (-27.60, -59.35),
    (-24.90, -61.90),
  ];

  static const chile = <(double lat, double lon)>[
    (-21.50, -68.75),
    (-21.55, -69.55),
    (-28.00, -71.50),
    (-33.50, -71.80),
    (-38.50, -73.80),
    (-45.00, -74.50),
    (-55.30, -73.50),
    (-55.20, -68.80),
    (-52.00, -69.20),
    (-45.00, -71.00),
    (-38.00, -70.50),
    (-30.00, -70.20),
    (-24.00, -69.80),
  ];
}
