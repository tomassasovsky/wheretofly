import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/messaging_service.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final body = await readJsonBody(context.request);
  if (body == null) return jsonError(400, 'Invalid JSON body');
  final name = requireString(body, 'name');
  final memberIds = body['memberIds'];
  if (name == null || memberIds is! List) {
    return jsonError(400, 'name and memberIds are required');
  }
  try {
    final group = await AppContainer.instance.messagingService.createGroup(
      creatorId: userId,
      name: name,
      memberIds: memberIds.whereType<String>().toList(),
    );
    return jsonOk(group);
  } on MessagingException catch (e) {
    return jsonError(e.statusCode, e.message);
  }
}
