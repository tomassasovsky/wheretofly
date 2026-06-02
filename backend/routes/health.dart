import 'package:backend/app_container.dart';
import 'package:backend/config/app_config.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  await ensureContainer();
  final feed = await AppContainer.instance.zoneService.getFeed();
  return jsonOk({
    'status': 'ok',
    'version': AppConfig.version,
    'zoneFeedVersion': feed.version,
    'minClientVersion': AppConfig.minClientVersion,
  });
}
