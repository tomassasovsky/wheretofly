import 'package:backend/app_container.dart';
import 'package:backend/services/jwt_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Reads Bearer token from Authorization header.
String? bearerToken(Request request) {
  final header =
      request.headers['Authorization'] ?? request.headers['authorization'];
  if (header == null || !header.startsWith('Bearer ')) return null;
  return header.substring(7).trim();
}

/// Returns authenticated user id or null.
String? authenticatedUserId(RequestContext context) {
  final token = bearerToken(context.request);
  if (token == null) return null;
  return context.read<JwtService>().userIdFromToken(token);
}

/// Standard 401 JSON response for missing or invalid auth.
Response unauthorized() => Response.json(
  statusCode: 401,
  body: {'error': 'Unauthorized'},
);

/// Adds CORS headers and handles OPTIONS preflight requests.
Handler corsMiddleware(Handler handler) {
  return (context) async {
    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: 204,
        headers: _corsHeaders,
      );
    }
    final response = await handler(context);
    return response.copyWith(headers: {...response.headers, ..._corsHeaders});
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type, If-None-Match',
};

/// Ensures [AppContainer] is initialized before route handlers run.
Future<void> ensureContainer() => AppContainer.initialize();
