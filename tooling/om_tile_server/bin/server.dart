// ignore_for_file: avoid_print

import 'dart:io';

import 'package:om_smoke/om/dwd_icon_grid.dart';
import 'package:om_smoke/om/om_file_reader.dart';
import 'package:om_smoke/om/om_http_backend.dart';
import 'package:om_smoke/om/om_spatial_url.dart';
import 'package:om_smoke/om/om_wasm_module.dart';
import 'package:om_smoke/om/wasm_run_cli.dart';
import 'package:om_tile_server/wind_arrow_json.dart';
import 'package:om_tile_server/wind_tile_png.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

const _model = 'dwd_icon';
const _variable = 'wind_gusts_10m';
const _timeStep = 'current_time_1H';

Future<void> main(List<String> args) async {
  final repoRoot = args.isNotEmpty ? args[0] : Directory.current.path;
  final port = args.length > 1 ? int.parse(args[1]) : 8765;
  final wasmPath = '$repoRoot/assets/om/om_reader_wasm.wasm';

  await ensureWasmRunCliLibrary();
  await OmWasmModule.ensureInitialized(wasmPath: wasmPath);
  final omUrl = await OmSpatialUrlResolver().resolveOmFileUrl();
  print('OM file: $omUrl');
  final backend = OmHttpBackend();
  final readers = await openWindReaders(Uri.parse(omUrl), backend);

  final router = Router()
    ..get('/health', (Request _) => Response.ok('ok'))
    ..get('/<z>/<x>/<y>.png', (Request request, String z, String x, String y) {
      return _pngHandler(readers.gust, z, x, y);
    })
    ..get('/<z>/<x>/<y>.json', (Request request, String z, String x, String y) {
      return _jsonHandler(readers.u, readers.v, z, x, y);
    });

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    port,
  );
  print(
    'Wind tile server http://${server.address.host}:${server.port}/<z>/<x>/<y>.{{png,json}}',
  );
  print(
    'iOS simulator: flutter run --dart-define=WIND_TILE_BASE_URL=http://127.0.0.1:$port',
  );
}

Future<Response> _pngHandler(
  OmFileReader gustReader,
  String z,
  String x,
  String y,
) async {
  try {
    final zi = int.parse(z);
    final xi = int.parse(x);
    final yi = int.parse(y);
    final tileRead = DwdIconTileRead.forTile(zi, xi, yi);
    final values = await DwdIconTileRead.readValues(
      gustReader.readFloat32,
      tileRead,
    );
    final png = encodeWindTilePng(values: values, tileRead: tileRead);
    return Response.ok(
      png,
      headers: {
        'Content-Type': 'image/png',
        'Cache-Control': 'public,max-age=300',
      },
    );
  } on Object catch (error) {
    return Response.internalServerError(body: '$error');
  }
}

Future<Response> _jsonHandler(
  OmFileReader uReader,
  OmFileReader vReader,
  String z,
  String x,
  String y,
) async {
  try {
    final zi = int.parse(z);
    final xi = int.parse(x);
    final yi = int.parse(y);
    final tileRead = DwdIconTileRead.forTile(zi, xi, yi);
    final u = await DwdIconTileRead.readValues(uReader.readFloat32, tileRead);
    final v = await DwdIconTileRead.readValues(vReader.readFloat32, tileRead);
    final body = encodeWindArrowJson(u: u, v: v, tileRead: tileRead);
    return Response.ok(
      body,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public,max-age=300',
      },
    );
  } on Object catch (error) {
    return Response.internalServerError(body: '$error');
  }
}
