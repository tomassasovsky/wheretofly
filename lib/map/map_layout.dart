import 'package:flutter/widgets.dart';

/// Shared layout constants for map overlay positioning.
abstract final class MapLayout {
  /// Clears the floating search bar.
  static const topOverlayInset = 76.0;

  /// Padding below the config bar inside the bottom [SafeArea].
  static const configBarBottomPadding = 12.0;

  /// Approximate height of the bottom config bar content.
  static const configBarContentHeight = 56.0;

  /// Gap between the config bar and the zone detail fly-result card.
  static const detailAboveChromeGap = 12.0;

  /// Gap between the config bar and the right FAB column.
  static const fabAboveConfigBar = 12.0;

  /// Legacy name: config bar block without safe area (≈68px).
  static const bottomChromeHeight =
      configBarContentHeight + configBarBottomPadding;

  /// Legacy name: camera/FAB inset when safe area is zero (~80px).
  static const bottomOverlayInset = bottomChromeHeight + fabAboveConfigBar + 38;

  /// Total height of the bottom config bar including home-indicator padding.
  static double configBarStackHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom +
        configBarBottomPadding +
        configBarContentHeight;
  }

  /// `Positioned.bottom` for the zone detail fly-result card.
  static double zoneDetailBottom(BuildContext context) {
    return configBarStackHeight(context) + detailAboveChromeGap;
  }

  /// `Positioned.bottom` for the right FAB column.
  static double fabColumnBottom(BuildContext context) {
    return configBarStackHeight(context) + fabAboveConfigBar;
  }

  /// Bottom padding for the map camera and tile layers.
  static double mapCameraBottomInset(BuildContext context) {
    return fabColumnBottom(context) + 32;
  }
}
