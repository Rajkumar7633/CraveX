import 'package:dartz/dartz.dart';
import 'package:zomato_clone/core/error/failures.dart';
import 'package:zomato_clone/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required String userType,
  });

  Future<Either<Failure, UserEntity>> loginWithGoogle();

  Future<Either<Failure, UserEntity>> loginWithFacebook();

  Future<Either<Failure, bool>> sendOtp({
    required String phone,
  });

  Future<Either<Failure, UserEntity>> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<Either<Failure, bool>> resetPassword({
    required String email,
  });

  Future<Either<Failure, bool>> logout();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Future<Either<Failure, bool>> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  });

  Stream<UserEntity?> authStateChanges();
}
