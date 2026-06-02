import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/post_service.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String handle) async {
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final target = await AppContainer.instance.authService.getUserByHandle(
    handle,
  );
  if (target == null) return jsonError(404, 'User not found');
  try {
    await AppContainer.instance.postService.follow(
      followerId: userId,
      targetId: target.id,
    );
    return jsonOk({'ok': true});
  } on PostServiceException catch (e) {
    return jsonError(e.statusCode, e.message);
  }
}
