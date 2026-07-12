import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final _dio = ApiClient().authDio;

  Future<void> sendOtp(String phone) async {
    await _dio.post('/api/v1/auth/otp/send', data: {'phone': '+91$phone'});
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp, {String? referralCode}) async {
    final resp = await _dio.post('/api/v1/auth/otp/verify', data: {
      'phone': '+91$phone',
      'otp': otp,
      if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
    });
    final data = resp.data as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    await ApiClient().setTokens(accessToken, refreshToken);
    // Persist user data
    if (data['user'] != null) {
      final prefs = await SharedPreferences.getInstance();
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      await prefs.setString(AppConstants.userDataKey, _userToString(user));
    }
    return data;
  }

  Future<User?> getMe() async {
    try {
      final resp = await _dio.get('/api/v1/auth/me');
      return User.fromJson(resp.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/v1/auth/logout');
    } catch (_) {}
    await ApiClient().clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userDataKey);
  }

  Future<User?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.userDataKey);
    if (raw == null) return null;
    return _userFromString(raw);
  }

  String _userToString(User u) =>
      '${u.id}|${u.name}|${u.phone ?? ''}|${u.email ?? ''}|${u.userType}|${u.walletBalance}|${u.isGoldMember}';

  User? _userFromString(String raw) {
    try {
      final parts = raw.split('|');
      return User(
        id: parts[0],
        name: parts[1],
        phone: parts[2].isEmpty ? null : parts[2],
        email: parts[3].isEmpty ? null : parts[3],
        userType: parts[4],
        walletBalance: double.tryParse(parts[5]) ?? 0,
        isGoldMember: parts[6] == 'true',
      );
    } catch (_) {
      return null;
    }
  }
}
