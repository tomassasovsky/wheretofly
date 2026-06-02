import 'dart:convert';

/// Decodes a JSON/JSONB column value from Postgres into a typed map.
Map<String, dynamic>? decodeJsonColumn(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String) {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  }
  return null;
}

/// Parses a JSON array of objects from dynamic API/list payloads.
List<Map<String, dynamic>> decodeJsonMapList(
  Object? value, {
  int? take,
}) {
  if (value is! List) return const [];
  final items = take == null ? value : value.take(take);
  final result = <Map<String, dynamic>>[];
  for (final item in items) {
    if (item is Map<String, dynamic>) {
      result.add(item);
    } else if (item is Map) {
      result.add(Map<String, dynamic>.from(item));
    }
  }
  return result;
}

/// Normalizes push platform identifiers to DB-allowed values.
String? normalizeDevicePlatform(String platform) {
  final normalized = switch (platform.toLowerCase()) {
    'ios' => 'ios',
    'android' => 'android',
    'macos' || 'linux' || 'windows' || 'fuchsia' => 'ios',
    _ => null,
  };
  return normalized;
}
