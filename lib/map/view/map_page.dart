import 'dart:async';

import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:location_repository/location_repository.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/cubit/map_search_cubit.dart';
import 'package:where_to_fly/map/cubit/map_weather_cubit.dart';
import 'package:where_to_fly/map/map_zone_sync.dart';
import 'package:where_to_fly/map/view/map_view.dart';

/// Map screen entry point — provides cubits and cross-feature listeners.
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MapCubit(
            context.read<FlightRulesRepository>(),
            settingsRepository: context.read<SettingsRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => MapSearchCubit(
            geocodingRepository: context.read<GeocodingRepository>(),
            locationRepository: context.read<LocationRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => MapWeatherCubit(
            weatherRepository: context.read<WeatherRepository>(),
          ),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MapCubit, MapState>(
            listenWhen: (previous, current) =>
                previous.selectedPoint != current.selectedPoint,
            listener: (context, state) {
              final point = state.selectedPoint;
              final weatherCubit = context.read<MapWeatherCubit>();
              if (point == null) {
                weatherCubit.clear();
                return;
              }
              unawaited(weatherCubit.fetchFor(point));
            },
          ),
          BlocListener<AuthCubit, AuthState>(
            listenWhen: (previous, current) =>
                !previous.isAuthenticated && current.isAuthenticated,
            listener: (context, state) {
              unawaited(syncMapZonesFromBackend(context));
              final point = context.read<MapCubit>().state.selectedPoint;
              if (point != null) {
                unawaited(context.read<MapWeatherCubit>().fetchFor(point));
              }
            },
          ),
        ],
        child: const MapView(),
      ),
    );
  }
}
