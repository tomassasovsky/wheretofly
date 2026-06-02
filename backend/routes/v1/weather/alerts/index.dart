import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();

  final alerts = AppContainer.instance.weatherAlertService;

  if (context.request.method == HttpMethod.get) {
    final items = await alerts.listSubscriptions(userId);
    return jsonOk({'subscriptions': items});
  }

  if (context.request.method == HttpMethod.post) {
    final body = await readJsonBody(context.request);
    if (body == null) return jsonError(400, 'Invalid JSON body');
    final label = requireString(body, 'label');
    final lat = requireDouble(body, 'lat');
    final lon = requireDouble(body, 'lon');
    if (label == null || lat == null || lon == null) {
      return jsonError(400, 'label, lat, and lon are required');
    }
    final threshold = requireDouble(body, 'windThresholdMs') ?? 8;
    final created = await alerts.createSubscription(
      userId: userId,
      label: label,
      lat: lat,
      lon: lon,
      windThresholdMs: threshold,
    );
    return jsonOk(created);
  }

  return Response(statusCode: 405);
}
