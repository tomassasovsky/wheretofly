import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/auth_service.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  await ensureContainer();
  final auth = AppContainer.instance.authService;
  switch (context.request.method) {
    case HttpMethod.post:
      final body = await readJsonBody(context.request);
      if (body == null) return jsonError(400, 'Invalid JSON body');
      final email = requireString(body, 'email');
      if (email == null) return jsonError(400, 'email is required');
      await auth.requestPasswordReset(email: email);
      return jsonOk({'ok': true});
    case HttpMethod.put:
      final body = await readJsonBody(context.request);
      if (body == null) return jsonError(400, 'Invalid JSON body');
      final token = requireString(body, 'token');
      final newPassword = requireString(body, 'newPassword');
      if (token == null || newPassword == null) {
        return jsonError(400, 'token and newPassword are required');
      }
      try {
        await auth.confirmPasswordReset(token: token, newPassword: newPassword);
        return jsonOk({'ok': true});
      } on AuthException catch (e) {
        return jsonError(e.statusCode, e.message);
      }
    default:
      return Response(statusCode: 405);
  }
}
