/// Inclusive start, exclusive end — matches Open-Meteo weather-map-layer.
class OmDimensionRange {
  const OmDimensionRange({required this.start, required this.end});

  final int start;
  final int end;
}
