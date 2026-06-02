import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/auth_service.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  await ensureContainer();
  final body = await readJsonBody(context.request);
  if (body == null) return jsonError(400, 'Invalid JSON body');
  final refreshToken = requireString(body, 'refreshToken');
  if (refreshToken == null) {
    return jsonError(400, 'refreshToken is required');
  }
  try {
    final tokens = await AppContainer.instance.authService.refresh(
      refreshToken: refreshToken,
    );
    return jsonOk(tokens.toJson());
  } on AuthException catch (e) {
    return jsonError(e.statusCode, e.message);
  }
}
