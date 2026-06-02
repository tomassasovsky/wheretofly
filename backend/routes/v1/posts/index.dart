import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/post_service.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();

  if (context.request.method == HttpMethod.get) {
    final cursor = context.request.uri.queryParameters['cursor'];
    final feed = await AppContainer.instance.postService.getFeed(
      userId: userId,
      cursor: cursor,
    );
    return jsonOk({'posts': feed});
  }

  if (context.request.method == HttpMethod.post) {
    final body = await readJsonBody(context.request);
    if (body == null) return jsonError(400, 'Invalid JSON body');
    final caption = requireString(body, 'caption') ?? '';
    final lat = requireDouble(body, 'locationLat');
    final lon = requireDouble(body, 'locationLon');
    final verdict = body['verdictSnapshot'];
    final zoneVersion = requireString(body, 'zoneVersion');
    try {
      final post = await AppContainer.instance.postService.createPost(
        authorId: userId,
        caption: caption,
        locationLat: lat,
        locationLon: lon,
        verdictSnapshot: verdict is Map<String, dynamic> ? verdict : null,
        zoneVersion: zoneVersion,
        media: body['media'] is List
            ? (body['media'] as List).whereType<Map<String, dynamic>>().toList()
            : const [],
      );
      return jsonOk(post);
    } on PostServiceException catch (e) {
      return jsonError(e.statusCode, e.message);
    }
  }
  return Response(statusCode: 405);
}
