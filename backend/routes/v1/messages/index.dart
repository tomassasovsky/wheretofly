import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();

  if (context.request.method == HttpMethod.get) {
    final threads = await AppContainer.instance.messagingService.listThreads(
      userId: userId,
    );
    return jsonOk({'threads': threads});
  }

  if (context.request.method == HttpMethod.post) {
    final body = await readJsonBody(context.request);
    if (body == null) return jsonError(400, 'Invalid JSON body');
    final otherUserId = requireString(body, 'userId');
    if (otherUserId == null) return jsonError(400, 'userId is required');
    final thread = await AppContainer.instance.messagingService
        .createDirectThread(
          userId: userId,
          otherUserId: otherUserId,
        );
    return jsonOk(thread);
  }
  return Response(statusCode: 405);
}
