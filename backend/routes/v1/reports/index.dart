import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();

  final body = await readJsonBody(context.request);
  if (body == null) return jsonError(400, 'Invalid JSON body');
  final targetType = requireString(body, 'targetType');
  final targetId = requireString(body, 'targetId');
  final reason = requireString(body, 'reason') ?? '';
  if (targetType == null || targetId == null) {
    return jsonError(400, 'targetType and targetId are required');
  }

  await AppContainer.instance.postService.reportContent(
    reporterId: userId,
    targetType: targetType,
    targetId: targetId,
    reason: reason,
  );
  return jsonOk({'ok': true});
}
