import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/constants/app_constants.dart';
import 'package:core/services/api_client.dart';
import 'package:core/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthState {
  final User? user;
  final String? userType;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.userType,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    String? userType,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      userType: userType ?? this.userType,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final ApiClient _apiClient;

  AuthNotifier(this.ref)
      : _apiClient = ApiClient(),
        super(const AuthState()) {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiClient.loadTokensFromPrefs();
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString(AppConstants.userTypeKey);
      final userData = prefs.getString(AppConstants.userDataKey);
      
      if (_apiClient.isAuthenticated && userData != null) {
        state = state.copyWith(
          isAuthenticated: true,
          userType: userType,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendOtp(String phoneNumber, String userType) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.authDio.post('/auth/send-otp', data: {
        'phone_number': phoneNumber,
        'user_type': userType,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp, String userType) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.authDio.post('/auth/verify-otp', data: {
        'phone_number': phoneNumber,
        'code': otp,
        'user_type': userType,
      });

      final accessToken = response.data['accessToken'] as String;
      final refreshToken = response.data['refreshToken'] as String;
      final userData = response.data['user'] as Map<String, dynamic>;

      await _apiClient.setTokens(accessToken, refreshToken);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userTypeKey, userType);
      await prefs.setString(AppConstants.userDataKey, userData.toString());

      state = state.copyWith(
        isAuthenticated: true,
        userType: userType,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loginWithEmail(String email, String password, String userType) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.authDio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'user_type': userType,
      });

      final accessToken = response.data['accessToken'] as String;
      final refreshToken = response.data['refreshToken'] as String;
      final userData = response.data['user'] as Map<String, dynamic>;

      await _apiClient.setTokens(accessToken, refreshToken);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userTypeKey, userType);
      await prefs.setString(AppConstants.userDataKey, userData.toString());

      state = state.copyWith(
        isAuthenticated: true,
        userType: userType,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiClient.clearTokens();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userTypeKey);
      await prefs.remove(AppConstants.userDataKey);

      state = const AuthState(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshToken() async {
    try {
      final response = await _apiClient.authDio.post('/auth/refresh');
      final accessToken = response.data['accessToken'] as String;
      final refreshToken = response.data['refreshToken'] as String;
      await _apiClient.setTokens(accessToken, refreshToken);
    } catch (e) {
      await logout();
    }
  }
}
