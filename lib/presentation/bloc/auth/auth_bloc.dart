import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zomato_clone/core/error/failures.dart';
import 'package:zomato_clone/core/utils/logger.dart';
import 'package:zomato_clone/domain/entities/user_entity.dart';
import 'package:zomato_clone/domain/repositories/auth_repository.dart';
import 'package:zomato_clone/presentation/bloc/auth/auth_event.dart';
import 'package:zomato_clone/presentation/bloc/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthFacebookLoginRequested>(_onFacebookLoginRequested);
    on<AuthSendOtpRequested>(_onSendOtpRequested);
    on<AuthVerifyOtpRequested>(_onVerifyOtpRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthGetCurrentUserRequested>(_onGetCurrentUserRequested);
    on<AuthUpdateProfileRequested>(_onUpdateProfileRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await authRepository.loginWithEmailPassword(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) {
        AppLogger.error('Login failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (user) {
        AppLogger.info('Login successful for user: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await authRepository.registerWithEmailPassword(
      name: event.name,
      email: event.email,
      password: event.password,
      userType: event.userType,
    );

    result.fold(
      (failure) {
        AppLogger.error('Registration failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (user) {
        AppLogger.info('Registration successful for user: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await authRepository.loginWithGoogle();

    result.fold(
      (failure) {
        AppLogger.error('Google login failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (user) {
        AppLogger.info('Google login successful for user: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onFacebookLoginRequested(
    AuthFacebookLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await authRepository.loginWithFacebook();

    result.fold(
      (failure) {
        AppLogger.error('Facebook login failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (user) {
        AppLogger.info('Facebook login successful for user: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onSendOtpRequested(
    AuthSendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await authRepository.sendOtp(phone: event.phone);

    result.fold(
      (failure) {
        AppLogger.error('Send OTP failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (success) {
        AppLogger.info('OTP sent successfully');
        emit(const AuthOtpSent());
      },
    );
  }

  Future<void> _onVerifyOtpRequested(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await authRepository.verifyOtp(
      phone: event.phone,
      otp: event.otp,
    );

    result.fold(
      (failure) {
        AppLogger.error('OTP verification failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (user) {
        AppLogger.info('OTP verification successful for user: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await authRepository.resetPassword(email: event.email);

    result.fold(
      (failure) {
        AppLogger.error('Password reset failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (success) {
        AppLogger.info('Password reset email sent');
        emit(const AuthPasswordResetSent());
      },
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await authRepository.logout();

    result.fold(
      (failure) {
        AppLogger.error('Logout failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (success) {
        AppLogger.info('Logout successful');
        emit(const AuthUnauthenticated());
      },
    );
  }

  Future<void> _onGetCurrentUserRequested(
    AuthGetCurrentUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await authRepository.getCurrentUser();

    result.fold(
      (failure) {
        AppLogger.error('Get current user failed: ${failure.message}');
        emit(const AuthUnauthenticated());
      },
      (user) {
        if (user != null) {
          AppLogger.info('Current user found: ${user.email}');
          emit(AuthAuthenticated(user: user));
        } else {
          AppLogger.info('No current user found');
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await authRepository.updateProfile(
      userId: event.userId,
      data: event.data,
    );

    result.fold(
      (failure) {
        AppLogger.error('Update profile failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (success) {
        AppLogger.info('Profile updated successfully');
        // Refresh user data
        add(const AuthGetCurrentUserRequested());
      },
    );
  }

  Future<void> _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.isAuthenticated) {
      add(const AuthGetCurrentUserRequested());
    } else {
      emit(const AuthUnauthenticated());
    }
  }
}
