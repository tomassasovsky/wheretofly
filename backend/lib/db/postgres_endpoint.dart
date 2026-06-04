import 'package:backend/config/app_config.dart';
import 'package:postgres/postgres.dart';

/// Builds a Postgres [Endpoint] from [config].
///
/// When [AppConfig.postgresHost] is set (Docker / Portainer `POSTGRES_*` vars),
/// the password is taken as-is. Otherwise [AppConfig.databaseUrl] is parsed
/// (password must be URI-encoded if it contains `@`, `:`, etc.).
Endpoint postgresEndpointFor(AppConfig config) {
  final host = config.postgresHost;
  if (host != null && host.isNotEmpty) {
    return Endpoint(
      host: host,
      port: config.postgresPort,
      database: config.postgresDatabase,
      username: config.postgresUser,
      password: config.postgresPassword,
    );
  }

  final uri = Uri.parse(config.databaseUrl);
  final userInfo = uri.userInfo;
  String? username;
  String? password;
  if (userInfo.isNotEmpty) {
    final colon = userInfo.indexOf(':');
    if (colon >= 0) {
      username = Uri.decodeComponent(userInfo.substring(0, colon));
      password = Uri.decodeComponent(userInfo.substring(colon + 1));
    } else {
      username = Uri.decodeComponent(userInfo);
    }
  }

  return Endpoint(
    host: uri.host,
    port: uri.hasPort ? uri.port : 5432,
    database: uri.pathSegments.isNotEmpty
        ? uri.pathSegments.first.replaceFirst('/', '')
        : 'dondevolar',
    username: username,
    password: password,
  );
}
