import 'dart:io';

import 'package:backend/db/dev_seed.dart';

/// Seeds the dev database with demo pilots, posts, DMs, and follows.
///
/// Usage (from `backend/`):
///   export DATABASE_URL=postgresql://dondevolar:dondevolar@localhost:5432/dondevolar
///   dart run bin/seed.dart
///   dart run bin/seed.dart --reset
Future<void> main(List<String> args) async {
  final reset = args.contains('--reset') || args.contains('-r');

  stdout.writeln('🌱 Seeding dev database${reset ? ' (reset)' : ''}...');

  try {
    await DevSeed.fromEnvironment(reset: reset);
  } on StateError catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }

  stdout
    ..writeln()
    ..writeln('Done! Demo login:')
    ..writeln('  email:    ${DevSeed.demoEmail}')
    ..writeln('  password: ${DevSeed.demoPassword}')
    ..writeln('  handle:   @${DevSeed.demoHandle}')
    ..writeln()
    ..writeln('Also created 24 other pilots (*@dev.local, same password).');
}
