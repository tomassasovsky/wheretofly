import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/weather_service.dart';
import 'package:backend/util/json_response.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  await ensureContainer();
  final userId = authenticatedUserId(context);
  if (userId == null) return unauthorized();

  final lat = double.tryParse(context.request.uri.queryParameters['lat'] ?? '');
  final lon = double.tryParse(context.request.uri.queryParameters['lon'] ?? '');
  if (lat == null || lon == null) {
    return jsonError(400, 'lat and lon query parameters are required');
  }
  try {
    final snapshot = await AppContainer.instance.weatherService.getWeather(
      lat: lat,
      lon: lon,
    );
    return jsonOk(snapshot.toJson());
  } on WeatherServiceException catch (e) {
    return jsonError(502, e.message);
  }
}
