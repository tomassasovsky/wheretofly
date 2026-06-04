import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:where_to_fly/map/wind/om/open_meteo_wind_data.dart';
import 'package:where_to_fly/map/wind/om/wind_decode_support.dart';

/// Renders Open-Meteo wind gust tiles on a [TileLayer] (native Flutter).
class OpenMeteoWindTileProvider extends TileProvider {
  OpenMeteoWindTileProvider({OpenMeteoWindData? data})
      : _data = data ?? OpenMeteoWindData();

  final OpenMeteoWindData _data;

  /// Shared loader for gust tiles and wind-direction arrows.
  OpenMeteoWindData get data => _data;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _OpenMeteoWindTileImage(
      coordinates: coordinates,
      data: _data,
    );
  }
}

@immutable
class _OpenMeteoWindTileImage extends ImageProvider<_OpenMeteoWindTileImage> {
  const _OpenMeteoWindTileImage({
    required this.coordinates,
    required this.data,
  });

  final TileCoordinates coordinates;
  final OpenMeteoWindData data;

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
      codec: _loadCodec(key),
      scale: 1,
    );
  }

  Future<ui.Codec> _loadCodec(_OpenMeteoWindTileImage key) async {
    try {
      if (WindDecodeSupport.hasRemoteTileServer) {
        final bytes = await data.tilePngBytes(coordinates);
        return ui.instantiateImageCodec(bytes);
      }
      final image = await data.tileImage(coordinates);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      image.dispose();
      return ui.instantiateImageCodec(bytes);
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        developer.log(
          'Wind tile ${coordinates.z}/${coordinates.x}/${coordinates.y} failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _OpenMeteoWindTileImage && coordinates == other.coordinates;

  @override
  int get hashCode => coordinates.hashCode;
}
