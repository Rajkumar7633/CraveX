import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:zomato_clone/core/utils/logger.dart';

class PaymentService {
  final Razorpay _razorpay = Razorpay();
  Function(String)? _onPaymentSuccess;
  Function(String)? _onPaymentError;
  Function()? _onExternalWallet;

  PaymentService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void setCallbacks({
    Function(String)? onSuccess,
    Function(String)? onError,
    Function()? onExternalWallet,
  }) {
    _onPaymentSuccess = onSuccess;
    _onPaymentError = onError;
    _onExternalWallet = onExternalWallet;
  }

  void openPayment({
    required String key,
    required double amount,
    required String orderId,
    required String name,
    required String description,
    required String contact,
    required String email,
    String? prefillAddress,
    Map<String, dynamic>? notes,
    String? themeColor,
    String? orderIdFromServer,
  }) {
    final options = {
      'key': key,
      'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
      'name': name,
      'description': description,
      'order_id': orderIdFromServer,
      'prefill': {
        'contact': contact,
        'email': email,
        'name': name,
      },
      'external': {
        'wallets': ['paytm', 'phonepe', 'googlepay', 'amazonpay']
      },
      'notes': notes ?? {},
      'theme': {
        'color': themeColor ?? '#E23744',
      },
    };

    if (prefillAddress != null) {
      options['prefill']['address'] = prefillAddress;
    }

    try {
      _razorpay.open(options);
      AppLogger.info('Payment initiated for order: $orderId');
    } catch (e) {
      AppLogger.error('Payment initiation failed: $e');
      if (_onPaymentError != null) {
        _onPaymentError!(e.toString());
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    AppLogger.info('Payment successful: ${response.paymentId}');
    if (_onPaymentSuccess != null) {
      _onPaymentSuccess!(response.paymentId!);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    AppLogger.error('Payment failed: ${response.code} - ${response.message}');
    if (_onPaymentError != null) {
      _onPaymentError!('${response.code}: ${response.message}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppLogger.info('External wallet selected: ${response.walletName}');
    if (_onExternalWallet != null) {
      _onExternalWallet!();
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}

class PaymentResult {
  final bool isSuccess;
  final String? paymentId;
  final String? error;

  PaymentResult({
    required this.isSuccess,
    this.paymentId,
    this.error,
  });
}

class PaymentMethod {
  final String id;
  final String name;
  final String icon;
  final bool isAvailable;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    this.isAvailable = true,
  });
}

class PaymentMethods {
  static List<PaymentMethod> get availableMethods => [
    PaymentMethod(
      id: 'razorpay',
      name: 'Razorpay',
      icon: '💳',
    ),
    PaymentMethod(
      id: 'upi',
      name: 'UPI',
      icon: '📱',
    ),
    PaymentMethod(
      id: 'card',
      name: 'Credit/Debit Card',
      icon: '💳',
    ),
    PaymentMethod(
      id: 'netbanking',
      name: 'Net Banking',
      icon: '🏦',
    ),
    PaymentMethod(
      id: 'wallet',
      name: 'Wallet',
      icon: '👛',
    ),
  ];
}

class PaymentConfig {
  static const String razorpayKey = 'YOUR_RAZORPAY_KEY';
  static const String currency = 'INR';
  static const int timeout = 300; // 5 minutes
}
