import 'package:flutter/material.dart';

/// Map basemap and overlay styling aligned with the app Material theme.
abstract final class MapTheme {
  /// Shown behind the map while tiles load (matches near-white light surface).
  static const lightPlaceholder = Colors.white;

  /// Matches near-black dark surface.
  static const darkPlaceholder = Color(0xFF0A0714);

  static Color placeholderFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkPlaceholder : lightPlaceholder;

  /// Tap / search selection marker.
  static Color selectionFillFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFFC4B5FD) // lavender — 11:1 on #0A0714
          : const Color(0xFF4A1A8F); // deep violet — 11:1 on white

  /// Stroke colour adapts so it always achieves ≥3:1 against the fill.
  static Color selectionStrokeFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF1A0050) // dark violet on #C4B5FD — ~8:1
          : Colors.white; // white on #4A1A8F — ~11:1
}
