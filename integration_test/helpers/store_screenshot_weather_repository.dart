import 'package:latlong2/latlong.dart';
import 'package:weather_api_client/weather_api_client.dart';
import 'package:weather_repository/weather_repository.dart';

import 'store_screenshot_config.dart';

/// Stable weather for store captures (avoids emulator/backend flakes).
class StoreScreenshotWeatherRepository extends WeatherRepository {
  StoreScreenshotWeatherRepository()
      : super(
          apiClient: WeatherApiClient(
            baseUrl: Uri.parse('http://127.0.0.1:0'),
            accessTokenProvider: () async => null,
          ),
        );

  @override
  Future<WeatherSnapshot> getWeather(LatLng point) async {
    return StoreScreenshotConfig.weatherFixtureFor(point);
  }
}
