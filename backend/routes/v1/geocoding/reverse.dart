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

  final lat = double.tryParse(context.request.uri.queryParameters['lat'] ?? '');
  final lon = double.tryParse(context.request.uri.queryParameters['lon'] ?? '');
  if (lat == null || lon == null) {
    return jsonError(400, 'lat and lon query parameters are required');
  }

  try {
    final hit = await AppContainer.instance.geocodingService.reverse(
      lat: lat,
      lon: lon,
    );
    return jsonOk(hit.toJson());
  } on GeocodingServiceException catch (e) {
    if (e.message == 'no results') {
      return jsonError(404, 'no results');
    }
    return jsonError(502, 'geocoding upstream failed');
  }
}
