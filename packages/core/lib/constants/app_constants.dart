class AppConstants {
  static const String appName = 'CraveX';
  
  // Environment configuration
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  // API Base URLs per environment
  static String get _host {
    switch (environment) {
      case 'production':
        return 'api.cravex.com';
      case 'staging':
        return 'staging-api.cravex.com';
      default:
        return '10.0.2.2'; // Android emulator localhost
    }
  }
  
  static String get _protocol {
    switch (environment) {
      case 'production':
      case 'staging':
        return 'https';
      default:
        return 'http';
    }
  }
  
  static String get baseUrl => '$_protocol://$_host:8001';
  static String get restaurantBaseUrl => '$_protocol://$_host:8002';
  static String get orderBaseUrl => '$_protocol://$_host:8003';
  static String get riderBaseUrl => '$_protocol://$_host:8004';
  static String get paymentBaseUrl => '$_protocol://$_host:8005';
  static String get notificationBaseUrl => '$_protocol://$_host:8006';
  static String get apiGatewayUrl => '$_protocol://$_host:8080';

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String userTypeKey = 'user_type';
  static const String deviceIdKey = 'device_id';
  static const String fcmTokenKey = 'fcm_token';

  // User types
  static const String userTypeCustomer = 'customer';
  static const String userTypeRestaurant = 'restaurant';
  static const String userTypeRider = 'rider';
  static const String userTypeAdmin = 'admin';

  // Order states (matching backend state machine)
  static const String orderPending = 'PENDING';
  static const String orderConfirmed = 'CONFIRMED';
  static const String orderPreparing = 'PREPARING';
  static const String orderReady = 'READY';
  static const String orderPickedUp = 'PICKED_UP';
  static const String orderDelivered = 'DELIVERED';
  static const String orderCancelled = 'CANCELLED';

  // Payment methods
  static const String paymentCash = 'cod';
  static const String paymentCard = 'card';
  static const String paymentUpi = 'upi';
  static const String paymentWallet = 'wallet';
  static const String paymentRazorpay = 'razorpay';
  static const String paymentPaytm = 'paytm';

  // Pricing constants
  static const double defaultDeliveryFee = 40.0;
  static const double platformFee = 5.0;
  static const double packagingCharge = 10.0;
  
  // Cache durations (in seconds)
  static const int restaurantListCacheDuration = 120; // 2 minutes
  static const int menuCacheDuration = 300; // 5 minutes
  static const int itemAvailabilityCacheDuration = 10; // 10 seconds
  
  // OTP configuration
  static const int otpLength = 6;
  static const int otpResendCooldown = 30; // seconds
  static const int otpExpiry = 300; // 5 minutes
  
  // Rider configuration
  static const int riderAcceptanceTimeout = 15; // seconds
  static const int locationUpdateInterval = 3; // seconds
  
  // Pagination
  static const int defaultPageSize = 20;
}
