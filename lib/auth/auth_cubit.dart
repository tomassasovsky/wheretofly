import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.session,
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, session, errorMessage];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> checkSession() async {
    var session = await _repository.currentSession();
    if (session == null) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearSession: true,
        ),
      );
      return;
    }
    if (session.isAccessTokenExpired) {
      try {
        session = await _repository.refreshSession();
      } on Object {
        await _repository.logout();
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearSession: true,
          ),
        );
        return;
      }
    } else {
      try {
        await _repository.validateStoredSession();
      } on Object {
        await _repository.logout();
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearSession: true,
          ),
        );
        return;
      }
    }
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
        clearError: true,
      ),
    );
  }

  Future<void> login({required String email, required String password}) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ),
    );
    try {
      final session = await _repository.login(email: email, password: password);
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
          clearError: true,
        ),
      );
    } on AuthApiException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: e.message,
          clearSession: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'auth_login_failed',
          clearSession: true,
        ),
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ),
    );
    try {
      final session = await _repository.signUp(
        email: email,
        password: password,
        handle: handle,
        displayName: displayName,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
          clearError: true,
        ),
      );
    } on AuthApiException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: e.message,
          clearSession: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'auth_signup_failed',
          clearSession: true,
        ),
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearSession: true,
        clearError: true,
      ),
    );
  }
}
