import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:where_to_fly/map/google_map_style.dart';

/// Shared map defaults and one-time platform setup before any [GoogleMap].
abstract final class MapInitializer {
  static const argentinaCenter = LatLng(-38.4161, -63.6167);

  static const initialZoom = 4.5;

  static const initialCamera = CameraPosition(
    target: argentinaCenter,
    zoom: initialZoom,
  );

  /// Matches [GoogleMapStyle.darkJson] land fill — cover map until style
  /// applies.
  static const darkPlaceholderColor = Color(0xFF212121);

  /// Resolves map appearance from in-app [ThemeMode], not only [Theme].
  static Brightness mapBrightnessFor(
    BuildContext context,
    ThemeMode themeMode,
  ) {
    return switch (themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
  }

  /// Web only — native platforms use [GoogleMap.style] / [mapStyleFor].
  static MapColorScheme? mapColorSchemeFor(Brightness brightness) {
    if (!kIsWeb) return null;
    return brightness == Brightness.dark
        ? MapColorScheme.dark
        : MapColorScheme.light;
  }

  /// Custom roadmap style for dark mode; light uses the default map style.
  ///
  /// Pass to [GoogleMap.style] at build time.
  static String? mapStyleFor(Brightness brightness) {
    return brightness == Brightness.dark ? GoogleMapStyle.darkJson : null;
  }

  /// Android only — call from app bootstrap before `runApp`.
  static Future<void> initializePlatform() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final platform = GoogleMapsFlutterPlatform.instance;
    if (platform is GoogleMapsFlutterAndroid) {
      await platform.initializeWithRenderer(AndroidMapRenderer.latest);
    }
  }
}
