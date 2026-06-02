/// Repository exposing the device location as a domain value.
library;

// Re-export the failure types consumers need to handle.
export 'package:location_client/location_client.dart'
    show LocationException, LocationFailure;

export 'src/location_repository.dart';
