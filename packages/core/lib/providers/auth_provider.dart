import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

final _authService = AuthService();

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({User? user, bool? isLoading, String? error, bool? isAuthenticated}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await ApiClient().loadTokensFromPrefs();
    if (ApiClient().isAuthenticated) {
      final user = await _authService.getMe() ?? await _authService.getCachedUser();
      state = AuthState(user: user, isAuthenticated: user != null);
    } else {
      state = const AuthState(isAuthenticated: false);
    }
  }

  Future<bool> sendOtp(String phone) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.sendOtp(phone);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<User?> verifyOtp(String phone, String otp, {String? referralCode}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await _authService.verifyOtp(phone, otp, referralCode: referralCode);
      User? user;
      if (data['user'] != null) {
        user = User.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        user = await _authService.getMe();
      }
      state = AuthState(user: user, isAuthenticated: true);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return null;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(isAuthenticated: false);
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('409')) return 'Too many OTP requests. Please wait before retrying.';
    if (e.toString().contains('400')) return 'Invalid OTP. Please try again.';
    if (e.toString().contains('404')) return 'User not found. Please check the phone number.';
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
