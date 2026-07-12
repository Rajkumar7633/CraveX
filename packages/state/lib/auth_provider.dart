// lib/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:core/constants/app_constants.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthState {
  final String? token;
  final bool loading;
  final String? error;

  AuthState({this.token, this.loading = false, this.error});

  AuthState copyWith({String? token, bool? loading, String? error}) {
    return AuthState(
      token: token ?? this.token,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  AuthNotifier(this.ref) : super(AuthState());

  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  Future<void> login(String phone, String password) async {
    state = state.copyWith(loading: true);
    try {
      final response = await _dio.post('/auth/login', data: {
        'phone_number': phone,
        'password': password,
      });
      final token = response.data['token'];
      state = state.copyWith(token: token, loading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }

  Future<void> loginWithOtp(String phone, String otp) async {
    state = state.copyWith(loading: true);
    try {
      final response = await _dio.post('/auth/verify-otp', data: {
        'phone_number': phone,
        'code': otp,
      });
      final token = response.data['token'];
      state = state.copyWith(token: token, loading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }
}
