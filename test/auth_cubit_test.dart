import 'dart:convert';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:where_to_fly/auth/auth_cubit.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Builds a JWT-like access token with the given [exp] (seconds since epoch).
String _jwt(int exp) {
  String segment(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m)));
  return '${segment({'alg': 'HS256'})}.${segment({'exp': exp})}.sig';
}

void main() {
  late AuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  const expiredSession = AuthSession(
    accessToken: 'opaque-expired',
    refreshToken: 'refresh',
    expiresInSeconds: 900,
  );

  group('checkSession', () {
    blocTest<AuthCubit, AuthState>(
      'emits unauthenticated when there is no stored session',
      build: () {
        when(repository.currentSession).thenAnswer((_) async => null);
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'refreshes an expired token and becomes authenticated',
      build: () {
        final refreshed = AuthSession(
          accessToken: _jwt(
            DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          ),
          refreshToken: 'refresh2',
          expiresInSeconds: 3600,
        );
        when(repository.currentSession).thenAnswer((_) async => expiredSession);
        when(repository.refreshSession).thenAnswer((_) async => refreshed);
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'logs out when refreshing an expired token fails',
      build: () {
        when(repository.currentSession).thenAnswer((_) async => expiredSession);
        when(repository.refreshSession).thenThrow(
          const AuthApiException('expired', statusCode: 401),
        );
        when(repository.logout).thenAnswer((_) async {});
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated),
      ],
      verify: (_) => verify(repository.logout).called(1),
    );
  });

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'emits loading then authenticated on success',
      build: () {
        when(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => expiredSession);
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.login(email: 'a@b.com', password: 'pw'),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'surfaces the error message on AuthApiException',
      build: () {
        when(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthApiException('bad'));
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.login(email: 'a@b.com', password: 'bad'),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated)
            .having((s) => s.errorMessage, 'errorMessage', 'bad'),
      ],
    );
  });

  blocTest<AuthCubit, AuthState>(
    'logout clears the session',
    build: () {
      when(repository.logout).thenAnswer((_) async {});
      return AuthCubit(repository);
    },
    act: (cubit) => cubit.logout(),
    expect: () => [
      isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.unauthenticated)
          .having((s) => s.session, 'session', isNull),
    ],
    verify: (_) => verify(repository.logout).called(1),
  );
}
