import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:where_to_fly/map/wind_map_om_url_resolver.dart';

/// Renders Open-Meteo spatial wind/gust tiles on a [TileLayer].
///
/// Phase 0b: resolves metadata URL; tile decode/render is not implemented yet
/// (returns a transparent tile). Set `--dart-define=WIND_MAP_NATIVE=true` to
/// exercise the layer stack without the WebView.
class OpenMeteoWindTileProvider extends TileProvider {
  OpenMeteoWindTileProvider({WindMapOmUrlResolver? resolver})
      : _resolver = resolver ?? WindMapOmUrlResolver();

  final WindMapOmUrlResolver _resolver;

  Future<String>? _resolveFuture;

  Future<String> _sourceUrl() {
    return _resolveFuture ??= _resolver.resolve();
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _OpenMeteoWindTileImage(
      coordinates: coordinates,
      sourceUrlLoader: _sourceUrl,
    );
  }
}

@immutable
class _OpenMeteoWindTileImage extends ImageProvider<_OpenMeteoWindTileImage> {
  const _OpenMeteoWindTileImage({
    required this.coordinates,
    required this.sourceUrlLoader,
  });

  final TileCoordinates coordinates;
  final Future<String> Function() sourceUrlLoader;

  @override
  Future<_OpenMeteoWindTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _OpenMeteoWindTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(key, decode),
      scale: 1,
    );
  }

  Future<ui.Codec> _loadCodec(
    _OpenMeteoWindTileImage key,
    ImageDecoderCallback decode,
  ) async {
    // TODO(phase-0b): decode om tiles; colorize with WindColorscale.
    await key.sourceUrlLoader();
    final image = await _transparentImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is _OpenMeteoWindTileImage && coordinates == other.coordinates;

  @override
  int get hashCode => coordinates.hashCode;
}

Future<ui.Image> _transparentImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = 256.0;
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = const Color(0x00000000),
  );
  final picture = recorder.endRecording();
  return picture.toImage(size.toInt(), size.toInt());
}
