import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String handle) async {
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();

  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  final profile = await AppContainer.instance.authService.getUserByHandle(
    handle,
  );
  if (profile == null) return jsonError(404, 'User not found');
  return jsonOk(profile.toPublicJson());
}
