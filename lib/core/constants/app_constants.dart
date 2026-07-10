class AppConstants {
  // App Info
  static const String appName = 'Zomato Clone';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'https://api.zomato-clone.com/v1';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String languageKey = 'language';
  static const String themeKey = 'theme';
  
  // User Types
  static const String userTypeUser = 'user';
  static const String userTypeRestaurant = 'restaurant';
  static const String userTypeRider = 'rider';
  static const String userTypeAdmin = 'admin';
  
  // Order Status
  static const String orderPending = 'pending';
  static const String orderConfirmed = 'confirmed';
  static const String orderPreparing = 'preparing';
  static const String orderReady = 'ready';
  static const String orderPickedUp = 'picked_up';
  static const String orderDelivered = 'delivered';
  static const String orderCancelled = 'cancelled';
  
  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentCard = 'card';
  static const String paymentUPI = 'upi';
  static const String paymentWallet = 'wallet';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Image Quality
  static const int imageQuality = 85;
  
  // Distance
  static const double defaultSearchRadius = 5.0; // in km
  
  // Delivery
  static const int defaultDeliveryTime = 30; // in minutes
  static const double defaultDeliveryFee = 2.99;
  
  // Rating
  static const double minRating = 1.0;
  static const double maxRating = 5.0;
}
