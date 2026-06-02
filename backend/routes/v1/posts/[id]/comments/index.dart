import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/post_service.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();

  final posts = AppContainer.instance.postService;

  if (context.request.method == HttpMethod.get) {
    final comments = await posts.getComments(id);
    return jsonOk({'comments': comments});
  }

  if (context.request.method == HttpMethod.post) {
    final body = await readJsonBody(context.request);
    if (body == null) return jsonError(400, 'Invalid JSON body');
    final text = requireString(body, 'body');
    if (text == null || text.trim().isEmpty) {
      return jsonError(400, 'body is required');
    }
    final post = await posts.getPost(id);
    if (post == null) return jsonError(404, 'Post not found');
    try {
      final comment = await posts.addComment(
        postId: id,
        authorId: userId,
        body: text.trim(),
      );
      return jsonOk(comment);
    } on PostServiceException catch (e) {
      return jsonError(e.statusCode, e.message);
    }
  }

  return Response(statusCode: 405);
}
