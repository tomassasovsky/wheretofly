import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_repository/weather_repository.dart';
import 'package:where_to_fly/weather/weather_alerts_cubit.dart';

class _MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  late WeatherRepository repository;

  setUp(() {
    repository = _MockWeatherRepository();
    registerFallbackValue(const LatLng(0, 0));
  });

  const sub = WeatherAlertSubscription(
    id: 's1',
    label: 'Home',
    lat: -34.6,
    lon: -58.4,
    windThresholdMs: 8,
  );

  group('load', () {
    blocTest<WeatherAlertsCubit, WeatherAlertsState>(
      'emits loading then loaded with subscriptions',
      build: () {
        when(repository.listAlertSubscriptions).thenAnswer((_) async => [sub]);
        return WeatherAlertsCubit(weatherRepository: repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<WeatherAlertsState>()
            .having((s) => s.status, 'status', WeatherAlertsStatus.loading),
        isA<WeatherAlertsState>()
            .having((s) => s.status, 'status', WeatherAlertsStatus.loaded)
            .having((s) => s.subscriptions, 'subscriptions', [sub]),
      ],
    );

    blocTest<WeatherAlertsCubit, WeatherAlertsState>(
      'emits error on WeatherApiException',
      build: () {
        when(repository.listAlertSubscriptions).thenThrow(
          const WeatherApiException('boom', statusCode: 500),
        );
        return WeatherAlertsCubit(weatherRepository: repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<WeatherAlertsState>()
            .having((s) => s.status, 'status', WeatherAlertsStatus.loading),
        isA<WeatherAlertsState>()
            .having((s) => s.status, 'status', WeatherAlertsStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', 'boom'),
      ],
    );
  });

  group('remove', () {
    blocTest<WeatherAlertsCubit, WeatherAlertsState>(
      'optimistically removes the subscription on success',
      build: () {
        when(() => repository.deleteAlertSubscription(any()))
            .thenAnswer((_) async {});
        return WeatherAlertsCubit(weatherRepository: repository);
      },
      seed: () => const WeatherAlertsState(
        status: WeatherAlertsStatus.loaded,
        subscriptions: [sub],
      ),
      act: (cubit) => cubit.remove('s1'),
      expect: () => [
        isA<WeatherAlertsState>()
            .having((s) => s.subscriptions, 'subscriptions', isEmpty),
      ],
    );

    blocTest<WeatherAlertsCubit, WeatherAlertsState>(
      'rolls back and emits error when the delete fails',
      build: () {
        when(() => repository.deleteAlertSubscription(any())).thenThrow(
          const WeatherApiException('nope', statusCode: 500),
        );
        return WeatherAlertsCubit(weatherRepository: repository);
      },
      seed: () => const WeatherAlertsState(
        status: WeatherAlertsStatus.loaded,
        subscriptions: [sub],
      ),
      act: (cubit) => cubit.remove('s1'),
      expect: () => [
        isA<WeatherAlertsState>()
            .having((s) => s.subscriptions, 'subscriptions', isEmpty),
        predicate<WeatherAlertsState>(
          (s) =>
              s.status == WeatherAlertsStatus.error &&
              s.subscriptions.length == 1 &&
              s.errorMessage == 'nope',
        ),
      ],
    );
  });

  group('save', () {
    test('returns true and prepends the created subscription', () async {
      when(
        () => repository.createAlertSubscription(
          label: any(named: 'label'),
          point: any(named: 'point'),
          windThresholdMs: any(named: 'windThresholdMs'),
        ),
      ).thenAnswer((_) async => sub);
      final cubit = WeatherAlertsCubit(weatherRepository: repository);

      final ok =
          await cubit.save(label: 'Home', point: const LatLng(-34.6, -58.4));

      expect(ok, isTrue);
      expect(cubit.state.subscriptions, [sub]);
      await cubit.close();
    });

    test('returns false when creation fails', () async {
      when(
        () => repository.createAlertSubscription(
          label: any(named: 'label'),
          point: any(named: 'point'),
          windThresholdMs: any(named: 'windThresholdMs'),
        ),
      ).thenThrow(const WeatherApiException('fail'));
      final cubit = WeatherAlertsCubit(weatherRepository: repository);

      final ok =
          await cubit.save(label: 'Home', point: const LatLng(-34.6, -58.4));

      expect(ok, isFalse);
      await cubit.close();
    });
  });
}
