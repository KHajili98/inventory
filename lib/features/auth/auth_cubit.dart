import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/auth/auth_service.dart';
import 'package:inventory/models/auth_models.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final LoginResponse response;
  AuthAuthenticated(this.response);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class AuthCubit extends Cubit<AuthState> {
  final AuthService _service;

  AuthCubit({AuthService? service}) : _service = service ?? AuthService.instance, super(AuthInitial());

  /// Check stored session on app start
  Future<void> checkSession() async {
    final loginResponse = await _service.getLoginResponse();
    final token = await _service.getAccessToken();
    if (loginResponse != null && token != null && token.isNotEmpty) {
      emit(AuthAuthenticated(loginResponse));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login({required String username, required String password, required String loggedInInventoryId}) async {
    emit(AuthLoading());
    final result = await _service.login(username: username, password: password, loggedInInventoryId: loggedInInventoryId);
    switch (result) {
      case Success<LoginResponse>(:final data):
        emit(AuthAuthenticated(data));
      case Failure<LoginResponse>(:final message):
        emit(AuthError(message));
    }
  }

  Future<void> logout() async {
    await _service.logout();
    emit(AuthUnauthenticated());
  }
}
