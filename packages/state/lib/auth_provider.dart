// lib/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

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



  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true);
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
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
      final response = await _dio.post('/auth/otp', data: {
        'phoneNumber': phone,
        'otp': otp,
      });
      final token = response.data['token'];
      state = state.copyWith(token: token, loading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }
}
