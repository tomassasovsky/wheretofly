/// Shared JSON response helpers for API routes.
library;

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

Response jsonOk(Object? body, {Map<String, String> headers = const {}}) {
  return Response.json(
    body: body,
    headers: {...headers, 'content-type': 'application/json'},
  );
}

Response jsonError(int status, String message, {String? code}) {
  return Response.json(
    statusCode: status,
    body: {
      'error': message,
      if (code != null) 'code': code,
    },
  );
}

Future<Map<String, dynamic>?> readJsonBody(Request request) async {
  final raw = await request.body();
  if (raw.isEmpty) return null;
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) return null;
  return decoded;
}

String? requireString(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

double? requireDouble(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
