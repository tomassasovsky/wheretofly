import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';
import 'package:where_to_fly/map/view/widgets/config_bar.dart';
import 'package:where_to_fly/map/view/widgets/map_search_bar.dart';

import 'helpers/auth_router_test_helper.dart';
import 'helpers/map_test_helper.dart';
import 'helpers/pump_helpers.dart';

void main() {
  late MockAuthRepository authRepository;

  setUpAll(initMapTestDependencies);

  setUp(() {
    authRepository = MockAuthRepository();
    when(() => authRepository.currentSession()).thenAnswer((_) async => null);
  });

  testWidgets('MapPage renders scaffold with map chrome', (tester) async {
    final authCubit = AuthCubit(authRepository);
    addTearDown(authCubit.close);

    await tester.pumpWidget(
      buildMapPageTestWidget(
        authCubit: authCubit,
        authRepository: authRepository,
      ),
    );
    await pumpRouterFrames(tester);

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(MapSearchBar), findsOneWidget);
    expect(find.byType(ConfigBar), findsOneWidget);
    // Map tiles may fail HTTP in widget tests; layout chrome is what we assert.
  });
}
