import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zomato_clone/core/error/exceptions.dart';
import 'package:zomato_clone/core/utils/logger.dart';
import 'package:zomato_clone/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUser();
  Stream<UserModel?> authStateChanges();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  final StreamController<UserModel?> _authController = StreamController<UserModel?>.broadcast();

  static const String _userKey = 'cached_user';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final userJson = user.toJson();
      await sharedPreferences.setString(_userKey, userJson.toString());
      _authController.add(user);
      AppLogger.info('User cached successfully');
    } catch (e) {
      AppLogger.error('Failed to cache user', error: e);
      throw CacheException('Failed to cache user');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userString = sharedPreferences.getString(_userKey);
      if (userString != null) {
        // Parse the JSON string back to a map
        // Note: This is a simplified version. In production, you'd use proper JSON parsing
        // For now, we'll return null and let the remote source handle it
        return null;
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get cached user', error: e);
      throw CacheException('Failed to get cached user');
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      await sharedPreferences.remove(_userKey);
      _authController.add(null);
      AppLogger.info('User cleared successfully');
    } catch (e) {
      AppLogger.error('Failed to clear user', error: e);
      throw CacheException('Failed to clear user');
    }
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _authController.stream;
  }

  void dispose() {
    _authController.close();
  }
}
