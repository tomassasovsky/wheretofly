import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/notification_service.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();

  if (context.request.method == HttpMethod.post) {
    final body = await readJsonBody(context.request);
    if (body == null) return jsonError(400, 'Invalid JSON body');
    final token = requireString(body, 'token');
    final platform = requireString(body, 'platform');
    if (token == null || platform == null) {
      return jsonError(400, 'token and platform are required');
    }
    try {
      await AppContainer.instance.notificationService.registerDeviceToken(
        userId: userId,
        token: token,
        platform: platform,
      );
      return jsonOk({'registered': true});
    } on NotificationException catch (e) {
      return jsonError(e.statusCode, e.message);
    }
  }

  if (context.request.method == HttpMethod.delete) {
    final body = await readJsonBody(context.request);
    if (body == null) return jsonError(400, 'Invalid JSON body');
    final token = requireString(body, 'token');
    if (token == null) return jsonError(400, 'token is required');
    await AppContainer.instance.notificationService.unregisterDeviceToken(
      userId: userId,
      token: token,
    );
    return jsonOk({'unregistered': true});
  }

  return Response(statusCode: 405);
}
