import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';

/// Notifies [GoRouter] when [AuthCubit] auth status changes so route guards
/// re-run.
class RouterAuthRefresh extends ChangeNotifier {
  RouterAuthRefresh(AuthCubit authCubit) {
    _subscription = authCubit.stream.listen((state) {
      if (state.status == AuthStatus.loading) return;
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
