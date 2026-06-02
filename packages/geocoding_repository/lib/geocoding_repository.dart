/// Repository for geocoding queries with offline caching.
library;

// Re-export the result/exception types consumers need.
export 'package:geocoding_api_client/geocoding_api_client.dart'
    show GeocodeResult, GeocodingException, GeocodingFailure;

export 'src/geocoding_repository.dart';
