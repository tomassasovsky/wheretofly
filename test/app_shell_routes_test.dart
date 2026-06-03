import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:where_to_fly/app/router/app_routes.dart';

void main() {
  test(r'$appRoutes keeps shell tabs inside the shell only', () {
    final topLevelPaths =
        $appRoutes.whereType<GoRoute>().map((route) => route.path).toList();

    expect(topLevelPaths, isNot(contains('/map')));
    expect(topLevelPaths, isNot(contains('/feed')));
    expect(topLevelPaths, isNot(contains('/explore')));
    expect(topLevelPaths, isNot(contains('/messages')));
    expect(topLevelPaths, isNot(contains('/me')));
    expect(topLevelPaths, contains('/settings'));
    expect(topLevelPaths, contains('/auth/login'));
  });
}
