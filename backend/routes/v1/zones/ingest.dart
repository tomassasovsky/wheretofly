import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();

  final version = await AppContainer.instance.zoneIngestService
      .ingestAndPublish(
        outputPath: AppContainer.instance.config.zoneFeedPath,
      );
  return jsonOk({'zoneVersion': version});
}
