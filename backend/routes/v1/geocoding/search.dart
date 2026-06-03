import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/geocoding_service.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  await ensureContainer();

  final query = context.request.uri.queryParameters['q']?.trim() ?? '';
  if (query.isEmpty) {
    return jsonError(400, 'q query parameter is required');
  }

  final limitRaw = context.request.uri.queryParameters['limit'];
  final limit = int.tryParse(limitRaw ?? '') ?? 5;
  if (limit < 1 || limit > 20) {
    return jsonError(400, 'limit must be between 1 and 20');
  }

  try {
    final hits = await AppContainer.instance.geocodingService.search(
      query,
      limit: limit,
    );
    return jsonOk({
      'results': hits.map((hit) => hit.toJson()).toList(),
    });
  } on GeocodingServiceException catch (e) {
    if (e.message == 'no results') {
      return jsonError(404, 'no results');
    }
    return jsonError(502, 'geocoding upstream failed');
  }
}
