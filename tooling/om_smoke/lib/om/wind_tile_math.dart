import 'dart:math' as math;

double tile2lon(double x, int z) {
  return x / math.pow(2, z) * 360 - 180;
}

double tile2lat(double y, int z) {
  final n = math.pi - (2 * math.pi * y) / math.pow(2, z);
  return math.atan(0.5 * (math.exp(n) - math.exp(-n))) * 180 / math.pi;
}
