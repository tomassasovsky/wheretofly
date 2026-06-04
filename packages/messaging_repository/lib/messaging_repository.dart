/// Repository for direct messaging threads and notification preferences.
library;

// Re-export the model/exception types consumers need so callers depend on the
// repository rather than the data layer.
export 'package:messaging_api_client/messaging_api_client.dart'
    show
        ChatMessage,
        ChatThread,
        MessagingApiException,
        NotificationPreferences;

export 'src/messaging_repository.dart';
