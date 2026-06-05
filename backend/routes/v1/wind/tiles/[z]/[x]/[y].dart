import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/wind_tile_service.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(
  RequestContext context,
  String z,
  String x,
  String y,
) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  await ensureContainer();

  final yTile = y.endsWith('.png') ? y.substring(0, y.length - 4) : y;
  final zi = int.tryParse(z);
  final xi = int.tryParse(x);
  final yi = int.tryParse(yTile);
  if (zi == null || xi == null || yi == null) {
    return Response(statusCode: 400, body: 'Invalid tile coordinates');
  }

  try {
    final png = await AppContainer.instance.windTileService.gustPng(
      z: zi,
      x: xi,
      y: yi,
    );
    return Response.bytes(
      body: png,
      headers: {
        'Content-Type': 'image/png',
        'Cache-Control': 'public,max-age=300',
      },
    );
  } on WindTileServiceException catch (e) {
    return Response(statusCode: 503, body: e.message);
  } on Object catch (e) {
    return Response(statusCode: 500, body: '$e');
  }
}
