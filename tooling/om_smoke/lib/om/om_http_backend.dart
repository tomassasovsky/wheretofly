import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// HTTP range reader for `.om` spatial files on map-tiles.open-meteo.com.
class OmHttpBackend {
  OmHttpBackend({http.Client? client}) : _client = client ?? http.Client();

  /// Block-cache hits since process start.
  static int get blockCacheHits => _LruBlockCache.hits;

  /// Block-cache misses since process start.
  static int get blockCacheMisses => _LruBlockCache.misses;

  /// Block-cache hit rate since process start (0–1).
  static double get blockCacheHitRate => _LruBlockCache.hitRate;

  final http.Client _client;
  final _blockCache = _LruBlockCache(blockSize: 64 * 1024, maxBlocks: 512);

  int? _fileSize;
  String? _eTag;
  String? _lastModified;

  Future<int> fileSize(Uri url) async {
    if (_fileSize != null) return _fileSize!;
    final response = await _client.head(url);
    if (response.statusCode != 200) {
      throw OmHttpBackendException('HEAD failed: ${response.statusCode}');
    }
    final length = response.headers['content-length'];
    if (length == null) {
      throw OmHttpBackendException('Missing Content-Length');
    }
    _fileSize = int.parse(length);
    _eTag = response.headers['etag'];
    _lastModified = response.headers['last-modified'];
    return _fileSize!;
  }

  Future<Uint8List> getBytes(Uri url, int offset, int size) async {
    final total = await fileSize(url);
    if (offset < 0 || size <= 0 || offset + size > total) {
      throw OmHttpBackendException('Range out of bounds: $offset+$size/$total');
    }
    final blocks = <(int, int)>[];
    var pos = offset;
    final end = offset + size;
    while (pos < end) {
      final blockStart = (pos ~/ _blockCache.blockSize) * _blockCache.blockSize;
      blocks.add((blockStart, _blockCache.blockSize));
      pos = blockStart + _blockCache.blockSize;
    }
    final out = Uint8List(size);
    var outOffset = 0;
    for (final (blockStart, blockLen) in blocks) {
      final block = await _blockCache.get(
        () => _fetchRange(url, blockStart, blockLen, total),
        key: '${url}_$blockStart',
      );
      final copyStart = offset > blockStart ? offset - blockStart : 0;
      final copyEnd = (offset + size) < blockStart + block.length
          ? offset + size - blockStart
          : block.length;
      final len = copyEnd - copyStart;
      if (len > 0) {
        out.setRange(outOffset, outOffset + len, block, copyStart);
        outOffset += len;
      }
    }
    return out;
  }

  Future<Uint8List> _fetchRange(
    Uri url,
    int offset,
    int size,
    int total,
  ) async {
    final end = (offset + size - 1).clamp(0, total - 1);
    final headers = <String, String>{
      'Range': 'bytes=$offset-$end',
    };
    if (_eTag != null) headers['If-Match'] = _eTag!;
    if (_lastModified != null) {
      headers['If-Unmodified-Since'] = _lastModified!;
    }
    final response = await _client.get(url, headers: headers);
    if (response.statusCode != 206 && response.statusCode != 200) {
      throw OmHttpBackendException('GET range failed: ${response.statusCode}');
    }
    return Uint8List.fromList(response.bodyBytes);
  }
}

class OmHttpBackendException implements Exception {
  OmHttpBackendException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _LruBlockCache {
  _LruBlockCache({required this.blockSize, required this.maxBlocks});

  final int blockSize;
  final int maxBlocks;
  final _map = <String, Uint8List>{};

  static int hits = 0;
  static int misses = 0;

  /// Block-cache hit rate since process start (0–1).
  static double get hitRate {
    final total = hits + misses;
    return total == 0 ? 0 : hits / total;
  }

  Future<Uint8List> get(
    Future<Uint8List> Function() loader, {
    required String key,
  }) async {
    final cached = _map.remove(key);
    if (cached != null) {
      hits++;
      _map[key] = cached;
      return cached;
    }
    misses++;
    final value = await loader();
    _map[key] = value;
    while (_map.length > maxBlocks) {
      _map.remove(_map.keys.first);
    }
    return value;
  }
}
