import 'dart:io';

import 'package:backend/config/app_config.dart';
import 'package:backend/db/postgres_endpoint.dart';
import 'package:postgres/postgres.dart';

/// PostgreSQL access and migration runner.
class Database {
  /// Wraps an open [Connection].
  Database(this._connection);

  final Connection _connection;

  /// Opens a Postgres connection using the configured database URL.
  static Future<Database> connect(AppConfig config) async {
    final endpoint = postgresEndpointFor(config);
    final connection = await Connection.open(
      endpoint,
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    return Database(connection);
  }

  /// Underlying postgres driver connection for raw SQL.
  Connection get connection => _connection;

  /// Applies bundled SQL migrations when the migration file is found.
  Future<void> runMigrations() async {
    const relativePath = 'lib/db/migrations/001_initial.sql';
    final migrationFile = _findMigrationFile(relativePath);
    if (migrationFile == null) {
      stderr.writeln(
        'Warning: migration file not found ($relativePath); '
        'run SQL manually against Postgres.',
      );
      return;
    }
    final sql = await migrationFile.readAsString();
    final statements = sql
        .replaceAll(RegExp(r'--[^\n]*'), '')
        .split(';')
        .map((statement) => statement.trim())
        .where((statement) => statement.isNotEmpty);
    for (final statement in statements) {
      await _connection.execute(statement);
    }
  }

  static File? _findMigrationFile(String relativePath) {
    var dir = Directory.current;
    for (var depth = 0; depth < 6; depth++) {
      final candidate = File('${dir.path}/$relativePath');
      if (candidate.existsSync()) return candidate;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }

  /// Closes the Postgres connection.
  Future<void> close() => _connection.close();
}
