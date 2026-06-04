import 'package:where_to_fly/app/app_mode.dart';

/// Disables [AppMode.mapOnly] for tests that cover social/auth navigation.
void withFullAppModeForTests() {
  AppMode.mapOnlyOverride = false;
}

/// Restores production [AppMode.mapOnly] after a test file or case.
void restoreAppModeAfterTests() {
  AppMode.mapOnlyOverride = null;
}
