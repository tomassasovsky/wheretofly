/// Display-name tweaks for Argentine Spanish (geocoding labels).
abstract final class PlaceNameDisplay {
  static const _replacements = <(String, String)>[
    ('Falkland Islands (Malvinas)', 'Islas Malvinas'),
    ('Falkland Islands', 'Islas Malvinas'),
    ('Falkland Is.', 'Islas Malvinas'),
  ];

  /// Applies known place-name substitutions to a comma-separated label.
  static String localize(String label) {
    var result = label;
    for (final (from, to) in _replacements) {
      result = result.replaceAll(from, to);
    }
    return result;
  }
}
