import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String userType;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.userType,
  });

  @override
  List<Object?> get props => [name, email, password, userType];
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}

class AuthFacebookLoginRequested extends AuthEvent {
  const AuthFacebookLoginRequested();
}

class AuthSendOtpRequested extends AuthEvent {
  final String phone;

  const AuthSendOtpRequested({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class AuthVerifyOtpRequested extends AuthEvent {
  final String phone;
  final String otp;

  const AuthVerifyOtpRequested({
    required this.phone,
    required this.otp,
  });

  @override
  List<Object?> get props => [phone, otp];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  const AuthResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthGetCurrentUserRequested extends AuthEvent {
  const AuthGetCurrentUserRequested();
}

class AuthUpdateProfileRequested extends AuthEvent {
  final String userId;
  final Map<String, dynamic> data;

  const AuthUpdateProfileRequested({
    required this.userId,
    required this.data,
  });

  @override
  List<Object?> get props => [userId, data];
}

class AuthStatusChanged extends AuthEvent {
  final bool isAuthenticated;

  const AuthStatusChanged({required this.isAuthenticated});

  @override
  List<Object?> get props => [isAuthenticated];
}
