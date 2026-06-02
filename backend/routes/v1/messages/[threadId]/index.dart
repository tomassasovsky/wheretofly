import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/messaging_service.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String threadId) async {
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();

  if (context.request.method == HttpMethod.get) {
    final cursor = context.request.uri.queryParameters['cursor'];
    try {
      final messages = await AppContainer.instance.messagingService
          .listMessages(
            threadId: threadId,
            userId: userId,
            cursor: cursor,
          );
      return jsonOk({'messages': messages});
    } on MessagingException catch (e) {
      return jsonError(e.statusCode, e.message);
    }
  }

  if (context.request.method == HttpMethod.post) {
    final body = await readJsonBody(context.request);
    if (body == null) return jsonError(400, 'Invalid JSON body');
    final text = requireString(body, 'body') ?? '';
    try {
      final messaging = AppContainer.instance.messagingService;
      final message = await messaging.sendMessage(
        threadId: threadId,
        senderId: userId,
        body: text,
        mediaKey: requireString(body, 'mediaKey'),
      );
      final recipients = await messaging.otherMemberIds(
        threadId: threadId,
        userId: userId,
      );
      for (final recipientId in recipients) {
        await AppContainer.instance.notificationService.sendToUser(
          userId: recipientId,
          category: 'message',
          title: 'Nuevo mensaje',
          body: text,
          data: {'threadId': threadId},
        );
      }
      return jsonOk(message);
    } on MessagingException catch (e) {
      return jsonError(e.statusCode, e.message);
    }
  }
  return Response(statusCode: 405);
}
