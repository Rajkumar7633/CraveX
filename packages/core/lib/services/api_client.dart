import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/error_response.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio authDio;
  late final Dio restaurantDio;
  late final Dio orderDio;
  late final Dio riderDio;
  late final Dio paymentDio;
  late final Dio notificationDio;

  String? _accessToken;
  String? _refreshToken;

  ApiClient._internal() {
    authDio = _createDio(AppConstants.baseUrl, skipAuth: true);
    restaurantDio = _createDio(AppConstants.restaurantBaseUrl);
    orderDio = _createDio(AppConstants.orderBaseUrl);
    riderDio = _createDio(AppConstants.riderBaseUrl);
    paymentDio = _createDio(AppConstants.paymentBaseUrl);
    notificationDio = _createDio(AppConstants.notificationBaseUrl);
  }

  Dio _createDio(String baseUrl, {bool skipAuth = false}) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Prepend /api/v1 if needed
        final path = options.path;
        if (!path.startsWith('/api/v1') && path != '/health') {
          options.path = '/api/v1$path';
        }
        // Attach Bearer token
        if (!skipAuth && _accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (!skipAuth && error.response?.statusCode == 401 && _refreshToken != null) {
          // Attempt token refresh
          try {
            final refreshed = await _doRefresh();
            if (refreshed) {
              // Retry original request with new token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_accessToken';
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            }
          } catch (e) {
            log('Token refresh failed: $e');
            // Clear tokens on refresh failure
            await clearTokens();
          }
        }
        
        // Convert Dio error to ErrorResponse
        if (error.response != null) {
          final errorResponse = ErrorResponse.fromJson(
            error.response?.data as Map<String, dynamic>? ?? {},
          );
          final dioError = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: errorResponse,
          );
          return handler.next(dioError);
        }
        
        handler.next(error);
      },
    ));

    return dio;
  }

  Future<bool> _doRefresh() async {
    try {
      final resp = await authDio.post('/api/v1/auth/refresh',
          data: {'refreshToken': _refreshToken});
      final data = resp.data as Map<String, dynamic>;
      await setTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String? ?? _refreshToken!,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadTokensFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(AppConstants.accessTokenKey);
    _refreshToken = prefs.getString(AppConstants.refreshTokenKey);
  }

  Future<void> setTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, access);
    await prefs.setString(AppConstants.refreshTokenKey, refresh);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
  }

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
}
