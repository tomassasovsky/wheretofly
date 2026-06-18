import 'dart:convert';

/// Repairs strings that were UTF-8 but misread as Latin-1 (e.g. `LANÃS` → `LANÚS`).
String repairUtf8Text(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || !_looksMisencoded(trimmed)) return trimmed;

  try {
    final repaired = utf8.decode(latin1.encode(trimmed));
    if (repaired.contains('\uFFFD')) return trimmed;
    return repaired;
  } on Object {
    return trimmed;
  }
}

bool _looksMisencoded(String value) =>
    value.contains('Ã') || value.contains('Â') || value.contains('â');
