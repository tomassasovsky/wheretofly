import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:location_repository/location_repository.dart';
import 'package:messaging_repository/messaging_repository.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:social_repository/social_repository.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/app/app_mode.dart';
import 'package:where_to_fly/app/router/app_router.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/app/router/root_navigator_key.dart';
import 'package:where_to_fly/app/router/router_auth_refresh.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/messaging/cubit/notification_preferences_cubit.dart';
import 'package:where_to_fly/messaging/push/push_registration_service.dart';
import 'package:where_to_fly/settings/settings_cubit.dart';
import 'package:where_to_fly/theme/app_theme.dart';
import 'package:where_to_fly/weather/weather_alerts_cubit.dart';
import 'package:where_to_fly/zone_sync/zone_sync_service.dart';

/// Root application widget. Provides the repository layer and the app-wide
/// [SettingsCubit] to the widget tree.
class App extends StatefulWidget {
  const App({
    required this.settingsRepository,
    required this.flightRulesRepository,
    required this.locationRepository,
    required this.geocodingRepository,
    required this.authRepository,
    required this.weatherRepository,
    required this.socialRepository,
    required this.messagingRepository,
    required this.pushRegistrationService,
    required this.zoneSyncService,
    super.key,
  });

  final SettingsRepository settingsRepository;
  final FlightRulesRepository flightRulesRepository;
  final LocationRepository locationRepository;
  final GeocodingRepository geocodingRepository;
  final AuthRepository authRepository;
  final WeatherRepository weatherRepository;
  final SocialRepository socialRepository;
  final MessagingRepository messagingRepository;
  final PushRegistrationService pushRegistrationService;
  final ZoneSyncService zoneSyncService;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthCubit _authCubit = AuthCubit(widget.authRepository)
    ..checkSession();
  late final RouterAuthRefresh _routerRefresh = RouterAuthRefresh(_authCubit);
  late final GoRouter _router =
      createAppRouter(refreshListenable: _routerRefresh);

  @override
  void dispose() {
    _routerRefresh.dispose();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.settingsRepository),
        RepositoryProvider.value(value: widget.flightRulesRepository),
        RepositoryProvider.value(value: widget.locationRepository),
        RepositoryProvider.value(value: widget.geocodingRepository),
        RepositoryProvider.value(value: widget.authRepository),
        RepositoryProvider.value(value: widget.weatherRepository),
        RepositoryProvider.value(value: widget.socialRepository),
        RepositoryProvider.value(value: widget.messagingRepository),
        RepositoryProvider.value(value: widget.pushRegistrationService),
        RepositoryProvider.value(value: widget.zoneSyncService),
      ],
      child: BlocProvider.value(
        value: _authCubit,
        child: BlocProvider(
          create: (_) => SettingsCubit(widget.settingsRepository),
          child: BlocProvider(
            create: (_) =>
                WeatherAlertsCubit(weatherRepository: widget.weatherRepository),
            child: BlocProvider(
              create: (_) => NotificationPreferencesCubit(
                messagingRepository: widget.messagingRepository,
              ),
              child: MultiBlocListener(
                listeners: [
                  BlocListener<AuthCubit, AuthState>(
                    listenWhen: (previous, current) =>
                        current.isAuthenticated &&
                        (!previous.isAuthenticated ||
                            previous.status == AuthStatus.unknown),
                    listener: (context, authState) {
                      context.read<WeatherAlertsCubit>().load();
                      context.read<NotificationPreferencesCubit>().load();
                      unawaited(
                        widget.pushRegistrationService.registerForCurrentUser(),
                      );
                    },
                  ),
                  BlocListener<AuthCubit, AuthState>(
                    listenWhen: (previous, current) =>
                        previous.isAuthenticated && !current.isAuthenticated,
                    listener: (context, authState) {
                      context.read<WeatherAlertsCubit>().reset();
                      context.read<NotificationPreferencesCubit>().reset();
                      unawaited(widget.pushRegistrationService.unregister());
                      final navContext = rootNavigatorKey.currentContext;
                      if (navContext != null) {
                        if (AppMode.isMapOnly) {
                          const MapTabRoute().go(navContext);
                        } else {
                          const LoginRoute().go(navContext);
                        }
                      }
                    },
                  ),
                ],
                child: BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    return MaterialApp.router(
                      onGenerateTitle: (context) =>
                          AppLocalizations.of(context).appTitle,
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.light,
                      darkTheme: AppTheme.dark,
                      themeMode: state.themeMode,
                      locale: state.locale,
                      localizationsDelegates:
                          AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      routerConfig: _router,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
