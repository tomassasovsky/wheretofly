import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:location_repository/location_repository.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/zone_sync/zone_sync_service.dart';

/// Re-exposes app repositories for [StatefulShellRoute] branch navigators.
///
/// Shell branches can miss ancestors of [MaterialApp] in widget tests and some
/// go_router navigator layouts; this keeps map and social tabs able to read
/// data-layer dependencies.
class ShellProviderScope extends StatelessWidget {
  const ShellProviderScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(
          value: context.read<FlightRulesRepository>(),
        ),
        RepositoryProvider.value(
          value: context.read<SettingsRepository>(),
        ),
        RepositoryProvider.value(
          value: context.read<GeocodingRepository>(),
        ),
        RepositoryProvider.value(
          value: context.read<LocationRepository>(),
        ),
        RepositoryProvider.value(
          value: context.read<WeatherRepository>(),
        ),
        RepositoryProvider.value(
          value: context.read<ZoneSyncService>(),
        ),
      ],
      child: child,
    );
  }
}
