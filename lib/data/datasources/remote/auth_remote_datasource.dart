import 'package:dio/dio.dart';
import 'package:zomato_clone/core/error/exceptions.dart';
import 'package:zomato_clone/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserModel> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required String userType,
  });

  Future<UserModel> loginWithGoogle();

  Future<UserModel> loginWithFacebook();

  Future<bool> sendOtp({
    required String phone,
  });

  Future<UserModel> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<bool> resetPassword({
    required String email,
  });

  Future<bool> logout();

  Future<UserModel?> getCurrentUser();

  Future<UserModel> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      }
      throw ServerException(e.message ?? 'Login failed');
    }
  }

  @override
  Future<UserModel> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'user_type': userType,
        },
      );

      if (response.statusCode == 201) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      }
      throw ServerException(e.message ?? 'Registration failed');
    }
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    try {
      final response = await dio.post('/auth/google');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(response.data['message'] ?? 'Google login failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      }
      throw ServerException(e.message ?? 'Google login failed');
    }
  }

  @override
  Future<UserModel> loginWithFacebook() async {
    try {
      final response = await dio.post('/auth/facebook');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(response.data['message'] ?? 'Facebook login failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      }
      throw ServerException(e.message ?? 'Facebook login failed');
    }
  }

  @override
  Future<bool> sendOtp({required String phone}) async {
    try {
      final response = await dio.post(
        '/auth/send-otp',
        data: {'phone': phone},
      );

      if (response.statusCode == 200) {
        return response.data['success'] ?? false;
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to send OTP');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      }
      throw ServerException(e.message ?? 'Failed to send OTP');
    }
  }

  @override
  Future<UserModel> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await dio.post(
        '/auth/verify-otp',
        data: {
          'phone': phone,
          'otp': otp,
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(response.data['message'] ?? 'Invalid OTP');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      }
      throw ServerException(e.message ?? 'Invalid OTP');
    }
  }

  @override
  Future<bool> resetPassword({required String email}) async {
    try {
      final response = await dio.post(
        '/auth/reset-password',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return response.data['success'] ?? false;
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to reset password');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      }
      throw ServerException(e.message ?? 'Failed to reset password');
    }
  }

  @override
  Future<bool> logout() async {
    try {
      final response = await dio.post('/auth/logout');

      if (response.statusCode == 200) {
        return response.data['success'] ?? false;
      } else {
        throw ServerException(response.data['message'] ?? 'Logout failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      }
      throw ServerException(e.message ?? 'Logout failed');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await dio.get('/auth/me');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else if (response.statusCode == 401) {
        return null;
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get user');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      }
      if (e.response?.statusCode == 401) {
        return null;
      }
      throw ServerException(e.message ?? 'Failed to get user');
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await dio.put(
        '/auth/profile/$userId',
        data: data,
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to update profile');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      }
      throw ServerException(e.message ?? 'Failed to update profile');
    }
  }
}
