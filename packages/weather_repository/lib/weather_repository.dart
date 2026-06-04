/// Repository for weather snapshots and alert subscriptions.
library;

// Re-export the model/exception types consumers need so callers depend on the
// repository rather than the data layer.
export 'package:weather_api_client/weather_api_client.dart'
    show
        WeatherAdvisoryLevel,
        WeatherAlertSubscription,
        WeatherApiException,
        WeatherSnapshot;

export 'src/weather_repository.dart';
