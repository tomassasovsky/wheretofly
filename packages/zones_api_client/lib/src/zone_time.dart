/// Parses a NOTAM validity timestamp into a UTC [DateTime].
///
/// Accepts an ISO-8601 string (the on-the-wire feed format). Returns `null` for
/// a missing or unparseable value so an open-ended or absent window degrades
/// gracefully rather than throwing. The result is always normalized to UTC.
DateTime? parseUtcDateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  return parsed?.toUtc();
}
