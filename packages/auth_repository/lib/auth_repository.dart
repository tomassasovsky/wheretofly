/// Repository for authentication sessions.
library;

// Re-export the model/exception types consumers need so callers depend on the
// repository rather than the data layer.
export 'package:auth_api_client/auth_api_client.dart'
    show AuthApiException, AuthSession;

export 'src/auth_repository.dart';
