import 'package:backend/config/app_config.dart';
import 'package:backend/services/weather_service.dart';
import 'package:test/test.dart';

void main() {
  group('WeatherService advisory scoring', () {
    test('returns good for calm conditions', () async {
      final service = WeatherService(config: _testConfig());
      final snapshot = await service.getWeather(lat: -34.6, lon: -58.4);
      expect(snapshot.advisory['level'], 'good');
    });
  });
}

AppConfig _testConfig() {
  return const AppConfig(
    databaseUrl: '',
    redisUrl: '',
    jwtSecret: '',
    openWeatherApiKey: '',
    minioEndpoint: '',
    minioAccessKey: '',
    minioSecretKey: '',
    minioBucket: '',
    googleClientId: '',
    appleClientId: '',
    zoneFeedPath: '',
  );
}
