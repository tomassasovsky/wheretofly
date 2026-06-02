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
  final email = requireString(body, 'email');
  final password = requireString(body, 'password');
  if (email == null || password == null) {
    return jsonError(400, 'email and password are required');
  }
  try {
    final tokens = await AppContainer.instance.authService.login(
      email: email,
      password: password,
    );
    return jsonOk(tokens.toJson());
  } on AuthException catch (e) {
    return jsonError(e.statusCode, e.message);
  }
}
