import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

/// Validates that the bearer access token maps to an existing user.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();
  final exists = await AppContainer.instance.authService.userExists(userId);
  if (!exists) return unauthorized();
  return jsonOk({'valid': true});
}
