import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  await ensureContainer();

  final ifNoneMatch =
      context.request.headers['If-None-Match'] ??
      context.request.headers['if-none-match'];
  final feed = await AppContainer.instance.zoneService.getFeed(
    ifNoneMatch: ifNoneMatch,
  );
  if (feed.notModified) {
    return Response(statusCode: 304, headers: {'ETag': feed.etag});
  }
  return Response(
    body: feed.geojson,
    headers: {
      'content-type': 'application/geo+json',
      'ETag': feed.etag,
      'X-Zone-Version': feed.version,
      'X-Zone-Updated-At': feed.updatedAt.toUtc().toIso8601String(),
    },
  );
}
