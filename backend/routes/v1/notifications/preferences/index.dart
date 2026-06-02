import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();

  if (context.request.method == HttpMethod.get) {
    final prefs = await AppContainer.instance.notificationService
        .getNotificationPreferences(userId);
    return jsonOk(prefs);
  }

  if (context.request.method == HttpMethod.patch) {
    final body = await readJsonBody(context.request);
    if (body == null) return jsonError(400, 'Invalid JSON body');
    final prefs = await AppContainer.instance.notificationService
        .updateNotificationPreferences(
          userId: userId,
          follows: body['follows'] as bool?,
          messages: body['messages'] as bool?,
          comments: body['comments'] as bool?,
          weather: body['weather'] as bool?,
        );
    return jsonOk(prefs);
  }

  return Response(statusCode: 405);
}
