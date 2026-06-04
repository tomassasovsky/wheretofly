import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_to_fly/app/router/root_navigator_key.dart';

/// Reads app-wide providers when a [GoRouter] shell branch omits ancestors.
T readAppProvider<T>(BuildContext context) {
  try {
    return context.read<T>();
  } on Object {
    final root = rootNavigatorKey.currentContext;
    if (root != null) {
      return root.read<T>();
    }
    rethrow;
  }
}
