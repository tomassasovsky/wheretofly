import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resolves `latest.json` URLs to concrete `.om` file URLs (om:// protocol input).
class OmSpatialUrlResolver {
  OmSpatialUrlResolver({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  final _metaCache = <String, _MetaCacheEntry>{};

  Future<String> resolveOmFileUrl({
    String model = 'dwd_icon',
    String variable = 'wind_gusts_10m',
    String timeStep = 'current_time_1H',
  }) async {
    final latestUri = Uri.https(
      'map-tiles.open-meteo.com',
      '/data_spatial/$model/latest.json',
      {'time_step': timeStep, 'variable': variable},
    );
    final meta = await _loadMeta(latestUri);
    final modelRun = DateTime.parse(meta.referenceTime).toUtc();
    final validTime = _resolveValidTime(meta, timeStep);
    final path = latestUri.path.replaceFirst(
      '/latest.json',
      '/${modelRun.year.toString().padLeft(4, '0')}/'
          '${modelRun.month.toString().padLeft(2, '0')}/'
          '${modelRun.day.toString().padLeft(2, '0')}/'
          '${modelRun.hour.toString().padLeft(2, '0')}00Z/'
          '${validTime.year.toString().padLeft(4, '0')}-'
          '${validTime.month.toString().padLeft(2, '0')}-'
          '${validTime.day.toString().padLeft(2, '0')}T'
          '${validTime.hour.toString().padLeft(2, '0')}00.om',
    );
    return latestUri.replace(path: path).toString();
  }

  Future<_SpatialMeta> _loadMeta(Uri latestUri) async {
    final key = latestUri.toString();
    final cached = _metaCache[key];
    if (cached != null && !cached.isExpired) {
      return cached.meta;
    }
    final response = await _client.get(latestUri);
    if (response.statusCode != 200) {
      throw OmSpatialUrlException('metadata ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final meta = _SpatialMeta(
      referenceTime: json['reference_time'] as String,
      validTimes: (json['valid_times'] as List<dynamic>).cast<String>(),
    );
    _metaCache[key] = _MetaCacheEntry(meta);
    return meta;
  }

  DateTime _resolveValidTime(_SpatialMeta meta, String timeStep) {
    final validTimesMatch = RegExp(r'^valid_times_(\d+)$').firstMatch(timeStep);
    if (validTimesMatch != null) {
      final index = int.parse(validTimesMatch.group(1)!);
      if (index < 0 || index >= meta.validTimes.length) {
        throw OmSpatialUrlException('valid_times index out of range: $index');
      }
      return DateTime.parse(meta.validTimes[index]).toUtc();
    }

    final match = RegExp(
      r'^current_time(?:_(?<mod>[+-]?)(?<amount>\d+)(?<unit>[MHdm]))?$',
    ).firstMatch(timeStep);
    if (match == null) {
      return DateTime.parse(meta.validTimes.first).toUtc();
    }
    final amountStr = match.namedGroup('amount');
    final target = amountStr == null
        ? DateTime.now().toUtc().copyWith(
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            )
        : _offsetCurrentTime(match, amountStr);
    return _nearestValidTime(meta.validTimes, target);
  }

  DateTime _offsetCurrentTime(RegExpMatch match, String amountStr) {
    var amount = int.parse(amountStr);
    final mod = match.namedGroup('mod');
    if (mod == '-') amount = -amount;
    final unit = match.namedGroup('unit');
    final base = DateTime.now().toUtc().copyWith(
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
    return switch (unit) {
      'M' => base.add(Duration(minutes: amount)),
      'H' => base.add(Duration(hours: amount)),
      'd' => base.add(Duration(days: amount)),
      'm' => DateTime.utc(base.year, base.month + amount, base.day, base.hour),
      _ => throw OmSpatialUrlException('Unsupported time_step unit $unit'),
    };
  }

  DateTime _nearestValidTime(List<String> validTimes, DateTime target) {
    var best = DateTime.parse(validTimes.first).toUtc();
    var bestDelta = target.difference(best).inSeconds.abs();
    for (final raw in validTimes) {
      final candidate = DateTime.parse(raw).toUtc();
      final delta = target.difference(candidate).inSeconds.abs();
      if (delta < bestDelta) {
        best = candidate;
        bestDelta = delta;
      }
    }
    return best;
  }
}

class _SpatialMeta {
  const _SpatialMeta({
    required this.referenceTime,
    required this.validTimes,
  });

  final String referenceTime;
  final List<String> validTimes;
}

class _MetaCacheEntry {
  _MetaCacheEntry(this.meta) : fetchedAt = DateTime.now();

  final _SpatialMeta meta;
  final DateTime fetchedAt;

  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > const Duration(seconds: 60);
}

class OmSpatialUrlException implements Exception {
  OmSpatialUrlException(this.message);
  final String message;
  @override
  String toString() => message;
}
