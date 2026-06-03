import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_repository/location_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/cubit/map_cubit.dart';
import 'package:where_to_fly/map/cubit/map_search_cubit.dart';
import 'package:where_to_fly/map/map_camera_controller.dart';
import 'package:where_to_fly/map/view/map_search_listeners.dart';

class _MockGeocodingRepository extends Mock implements GeocodingRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late _MockGeocodingRepository geocoding;
  late _MockLocationRepository location;
  late TextEditingController searchController;
  late FocusNode searchFocusNode;
  late MapCameraController mapController;
  late MapSearchCubit searchCubit;
  late MapCubit mapCubit;

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  setUp(() {
    geocoding = _MockGeocodingRepository();
    location = _MockLocationRepository();
    searchController = TextEditingController();
    searchFocusNode = FocusNode();
    mapController = MapCameraController();
    searchCubit = MapSearchCubit(
      geocodingRepository: geocoding,
      locationRepository: location,
    );
    mapCubit = MapCubit(FlightRulesRepository());
  });

  tearDown(() {
    searchController.dispose();
    searchFocusNode.dispose();
    searchCubit.close();
    mapCubit.close();
  });

  Future<void> pumpListeners(
    WidgetTester tester, {
    required void Function(LatLng point) onCheckPoint,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<MapSearchCubit>.value(value: searchCubit),
              BlocProvider<MapCubit>.value(value: mapCubit),
            ],
            child: MapSearchListeners(
              searchController: searchController,
              searchFocusNode: searchFocusNode,
              mapController: mapController,
              onCheckPoint: onCheckPoint,
              child: const SizedBox(key: Key('child')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('focusPoint invokes onCheckPoint when resolving address', (
    tester,
  ) async {
    LatLng? checkedPoint;

    when(() => location.currentLocation()).thenAnswer(
      (_) async => const LatLng(-34.6, -58.4),
    );

    await pumpListeners(
      tester,
      onCheckPoint: (point) => checkedPoint = point,
    );

    await searchCubit.locateMe();
    await tester.pumpAndSettle();

    expect(checkedPoint, const LatLng(-34.6, -58.4));
    expect(searchCubit.state.focusPoint, isNull);
  });

  testWidgets('locationFailure shows localized snackbar', (tester) async {
    when(() => location.currentLocation()).thenThrow(
      const LocationException(LocationFailure.permissionDenied),
    );

    await pumpListeners(tester, onCheckPoint: (_) {});

    await searchCubit.locateMe();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('resolvedAddressLabel updates search field', (tester) async {
    when(() => geocoding.reverse(any())).thenAnswer(
      (_) async => const GeocodeResult(
        label: 'Plaza de Mayo, Buenos Aires',
        point: LatLng(-34.608, -58.37),
      ),
    );

    await pumpListeners(tester, onCheckPoint: (_) {});

    await searchCubit.resolveAddressForPoint(const LatLng(-34.608, -58.37));
    await tester.pump();

    expect(searchController.text, 'Plaza de Mayo, Buenos Aires');
    expect(searchCubit.state.resolvedAddressLabel, isNull);
  });
}
