import 'package:geocoding_api_client/geocoding_api_client.dart';
import 'package:latlong2/latlong.dart';
import 'package:storage/storage.dart';

/// Repository: geocodes queries via [GeocodingApiClient], caching successful
/// lookups in [Storage] and falling back to the cache when the network
/// is unavailable so search keeps working offline.
class GeocodingRepository {
  GeocodingRepository({
    required GeocodingApiClient apiClient,
    Storage? storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  final GeocodingApiClient _apiClient;
  final Storage? _storage;

  static const _prefix = 'geocode_';
  static const _reversePrefix = 'geocode_rev_';

  /// Searches for [query]. Caches the first result on success; on a network
  /// error returns a previously cached result when available.
  Future<List<GeocodeResult>> search(String query) async {
    try {
      final results = await _apiClient.search(query);
      if (results.isNotEmpty) {
        await _cache(query, results.first);
      }
      return results;
    } on GeocodingException catch (e) {
      if (e.reason == GeocodingFailure.network) {
        final cached = _cached(query);
        if (cached != null) return [cached];
      }
      rethrow;
    }
  }

  /// Reverse-geocodes [point], with offline cache fallback on network errors.
  Future<GeocodeResult> reverse(LatLng point) async {
    final cached = _cachedReverse(point);
    try {
      final result = await _apiClient.reverse(point);
      await _cacheReverse(point, result);
      return result;
    } on GeocodingException catch (e) {
      if (e.reason == GeocodingFailure.network && cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  String _key(String query) => '$_prefix${query.trim().toLowerCase()}';

  String _reverseKey(LatLng point) =>
      '$_reversePrefix${point.latitude.toStringAsFixed(4)}_'
      '${point.longitude.toStringAsFixed(4)}';

  Future<void> _cache(String query, GeocodeResult result) {
    final value =
        '${result.point.latitude}|${result.point.longitude}|${result.label}';
    return _storage?.write(_key(query), value) ?? Future<void>.value();
  }

  GeocodeResult? _cached(String query) {
    final raw = _storage?.read(_key(query));
    return _decodeCached(raw);
  }

  Future<void> _cacheReverse(LatLng point, GeocodeResult result) {
    final value =
        '${result.point.latitude}|${result.point.longitude}|${result.label}';
    return _storage?.write(_reverseKey(point), value) ?? Future<void>.value();
  }

  GeocodeResult? _cachedReverse(LatLng point) =>
      _decodeCached(_storage?.read(_reverseKey(point)));

  GeocodeResult? _decodeCached(String? raw) {
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    final lat = double.tryParse(parts[0]);
    final lon = double.tryParse(parts[1]);
    if (lat == null || lon == null) return null;
    return GeocodeResult(
      label: parts.sublist(2).join('|'),
      point: LatLng(lat, lon),
    );
  }
}
