import 'package:argentina_bounds/argentina_border_path.dart';
import 'package:argentina_bounds/argentina_bounds.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';

void main() {
  test('border path uses Natural Earth 10m multipolygon', () {
    expect(ArgentinaBorderPath.polygonCount, 8);
    expect(ArgentinaBorderPath.allRings.length, 8);
    expect(
      ArgentinaBorderPath.allRings.fold<int>(0, (n, r) => n + r.length),
      greaterThan(4000),
    );
  });

  test('major cities are selectable inside Argentina', () {
    for (final point in [
      const LatLng(-34.6037, -58.3816), // Buenos Aires
      const LatLng(-31.4201, -64.1888), // Córdoba
      const LatLng(-32.9442, -60.6505), // Rosario
      const LatLng(-32.8908, -68.8272), // Mendoza
      const LatLng(-24.7821, -65.4232), // Salta
      const LatLng(-38.0055, -57.5426), // Mar del Plata
      const LatLng(-41.1335, -71.3083), // Bariloche
      const LatLng(-54.8019, -68.3030), // Ushuaia (NE gap)
      const LatLng(-34.9215, -57.9545), // La Plata
    ]) {
      expect(ArgentinaBounds.contains(point), isTrue, reason: '$point');
    }
  });

  test('neighbors stay outside Argentina', () {
    expect(
      ArgentinaBounds.contains(const LatLng(-34.9011, -56.1645)),
      isFalse,
    );
    expect(
      ArgentinaBounds.contains(const LatLng(-34.4711, -57.8444)),
      isFalse,
    );
    expect(
      ArgentinaBounds.contains(const LatLng(-25.2637, -57.5759)),
      isFalse,
    );
    expect(
      ArgentinaBounds.contains(const LatLng(-33.4489, -70.6693)),
      isFalse,
    );
  });

  test('Ushuaia may be outside precise path but inside selection fallback', () {
    const ushuaia = LatLng(-54.8019, -68.3030);
    expect(ArgentinaBounds.containsPrecise(ushuaia), isFalse);
    expect(ArgentinaBounds.contains(ushuaia), isTrue);
  });
}
