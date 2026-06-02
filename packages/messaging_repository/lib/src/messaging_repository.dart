import 'package:messaging_api_client/messaging_api_client.dart';

/// Repository for threads, messages, and push settings.
class MessagingRepository {
  MessagingRepository({required MessagingApiClient apiClient})
      : _apiClient = apiClient;

  final MessagingApiClient _apiClient;

  Future<List<ChatThread>> threads() => _apiClient.fetchThreads();

  Future<ChatThread> createDirectThread({required String userId}) =>
      _apiClient.createDirectThread(userId: userId);

  Future<List<ChatMessage>> messages(String threadId) =>
      _apiClient.fetchMessages(threadId);

  Future<ChatMessage> sendMessage({
    required String threadId,
    required String body,
  }) =>
      _apiClient.sendMessage(threadId: threadId, body: body);

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) =>
      _apiClient.registerDeviceToken(token: token, platform: platform);

  Future<void> unregisterDeviceToken({required String token}) =>
      _apiClient.unregisterDeviceToken(token: token);

  Future<NotificationPreferences> notificationPreferences() =>
      _apiClient.fetchNotificationPreferences();

  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) =>
      _apiClient.updateNotificationPreferences(prefs);
}
