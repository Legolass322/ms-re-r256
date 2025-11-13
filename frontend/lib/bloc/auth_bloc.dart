import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository authRepository;

  Future<void> _onStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Restoring session...'));
    try {
      final user = await authRepository.restoreSession();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (error) {
      emit(AuthError(message: 'Failed to restore session: $error'));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in...'));
    try {
      developer.log('DEBUG: Starting login for user: ${event.username}', name: 'AuthBloc');
      final user = await authRepository.login(
        username: event.username,
        password: event.password,
      );
      developer.log('DEBUG: Login successful, user: ${user.username}, isAdmin: ${user.isAdmin}', name: 'AuthBloc');
      // Successfully logged in - emit authenticated state
      emit(AuthAuthenticated(user: user));
      developer.log('DEBUG: AuthAuthenticated state emitted', name: 'AuthBloc');
    } catch (error, stackTrace) {
      // Login failed - emit error state
      developer.log('ERROR: Login failed: $error', name: 'AuthBloc', error: error, stackTrace: stackTrace);
      emit(AuthError(message: 'Login failed: ${error.toString()}'));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Creating account...'));
    try {
      await authRepository.register(
        email: event.email,
        username: event.username,
        password: event.password,
      );
      final user = await authRepository.login(
        username: event.username,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } catch (error) {
      emit(AuthError(message: 'Registration failed: $error'));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}

