import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

/// Cron endpoint to evaluate weather alert subscriptions and send push.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  await ensureContainer();
  final config = AppContainer.instance.config;
  final secret = context.request.headers['x-cron-secret'];
  if (secret == null || secret != config.jwtSecret) {
    return jsonError(401, 'Unauthorized');
  }

  final sent = await AppContainer.instance.weatherAlertService.runAlertWorker();
  return jsonOk({'sent': sent});
}
