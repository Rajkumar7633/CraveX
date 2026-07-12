import 'package:equatable/equatable.dart';

class ErrorResponse extends Equatable {
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const ErrorResponse({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      message: json['message'] as String? ?? 'An error occurred',
      code: json['code'] as String?,
      statusCode: json['statusCode'] as int?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'statusCode': statusCode,
      'details': details,
    };
  }

  String getDisplayMessage() {
    // Map backend error codes to user-friendly messages
    switch (code) {
      case 'AUTH_INVALID_CREDENTIALS':
        return 'Invalid email or password';
      case 'AUTH_TOKEN_EXPIRED':
        return 'Session expired. Please login again';
      case 'AUTH_OTP_INVALID':
        return 'Invalid OTP. Please try again';
      case 'AUTH_OTP_EXPIRED':
        return 'OTP expired. Please request a new one';
      case 'AUTH_OTP_RATE_LIMIT':
        return 'Too many OTP requests. Please wait';
      case 'ORDER_NOT_FOUND':
        return 'Order not found';
      case 'RESTAURANT_CLOSED':
        return 'Restaurant is currently closed';
      case 'PAYMENT_FAILED':
        return 'Payment failed. Please try again';
      case 'VALIDATION_ERROR':
        return details?['field'] != null 
            ? 'Invalid ${details!['field']}: ${details!['message']}'
            : 'Invalid input data';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Too many requests. Please try again later';
      default:
        return message;
    }
  }

  @override
  List<Object?> get props => [message, code, statusCode, details];
}
