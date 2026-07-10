import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio authDio;
  late final Dio restaurantDio;
  late final Dio orderDio;
  String? _token;

  ApiClient._internal() {
    authDio = _createDio(AppConstants.baseUrl);
    restaurantDio = _createDio(AppConstants.restaurantBaseUrl);
    orderDio = _createDio(AppConstants.orderBaseUrl);
  }

  Dio _createDio(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
    ));

    return dio;
  }

  void setToken(String? token) => _token = token;
}
