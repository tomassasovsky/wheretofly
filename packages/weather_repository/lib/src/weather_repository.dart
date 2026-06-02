import 'package:latlong2/latlong.dart';
import 'package:weather_api_client/weather_api_client.dart';

/// Fetches weather for map coordinates via the backend proxy.
class WeatherRepository {
  WeatherRepository({required WeatherApiClient apiClient})
      : _apiClient = apiClient;

  final WeatherApiClient _apiClient;

  Future<WeatherSnapshot> getWeather(LatLng point) {
    return _apiClient.fetch(lat: point.latitude, lon: point.longitude);
  }

  Future<List<WeatherAlertSubscription>> listAlertSubscriptions() {
    return _apiClient.listAlertSubscriptions();
  }

  Future<WeatherAlertSubscription> createAlertSubscription({
    required String label,
    required LatLng point,
    double windThresholdMs = 8,
  }) {
    return _apiClient.createAlertSubscription(
      label: label,
      lat: point.latitude,
      lon: point.longitude,
      windThresholdMs: windThresholdMs,
    );
  }

  Future<void> deleteAlertSubscription(String id) {
    return _apiClient.deleteAlertSubscription(id);
  }
}
