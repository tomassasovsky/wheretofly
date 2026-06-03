import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:where_to_fly/map/map_initializer.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';

/// Wraps the router subtree with a one-shot hidden map to pre-warm the SDK.
class MapPrewarmHost extends StatefulWidget {
  const MapPrewarmHost({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<MapPrewarmHost> createState() => _MapPrewarmHostState();
}

class _MapPrewarmHostState extends State<MapPrewarmHost> {
  var _warmComplete = false;

  void _onWarmComplete() {
    if (_warmComplete) return;
    setState(() => _warmComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_warmComplete) {
      return widget.child;
    }

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        final brightness = MapInitializer.mapBrightnessFor(
          context,
          settings.themeMode,
        );

        return Stack(
          children: [
            widget.child,
            MapPrewarm(
              brightness: brightness,
              onWarmComplete: _onWarmComplete,
            ),
          ],
        );
      },
    );
  }
}

/// Hidden map used only to trigger native Maps SDK initialization.
class MapPrewarm extends StatelessWidget {
  const MapPrewarm({
    required this.brightness,
    required this.onWarmComplete,
    super.key,
  });

  final Brightness brightness;
  final VoidCallback onWarmComplete;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    return Offstage(
      child: SizedBox(
        width: 1,
        height: 1,
        child: GoogleMap(
          initialCameraPosition: MapInitializer.initialCamera,
          style: MapInitializer.mapStyleFor(brightness),
          colorScheme: MapInitializer.mapColorSchemeFor(brightness),
          onMapCreated: (_) => onWarmComplete(),
        ),
      ),
    );
  }
}
