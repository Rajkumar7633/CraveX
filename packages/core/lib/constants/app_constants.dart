class AppConstants {
  static const String appName = 'Zomato Clone';
  static const String baseUrl = 'http://localhost:8001';
  static const String restaurantBaseUrl = 'http://localhost:8002';
  static const String orderBaseUrl = 'http://localhost:8003';
  static const String paymentBaseUrl = 'http://localhost:8005';
  static const String riderBaseUrl = 'http://localhost:8004';

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  static const String userTypeCustomer = 'customer';
  static const String userTypeRestaurant = 'restaurant';
  static const String userTypeRider = 'rider';
  static const String userTypeAdmin = 'admin';

  static const String orderPlaced = 'placed';
  static const String orderAccepted = 'accepted';
  static const String orderPreparing = 'preparing';
  static const String orderReady = 'ready';
  static const String orderPickedUp = 'picked_up';
  static const String orderOnTheWay = 'on_the_way';
  static const String orderDelivered = 'delivered';
  static const String orderCancelled = 'cancelled';

  static const String paymentCash = 'cod';
  static const String paymentCard = 'card';
  static const String paymentUpi = 'upi';
  static const String paymentWallet = 'wallet';

  static const double defaultDeliveryFee = 40.0;
  static const double platformFee = 5.0;
  static const double packagingCharge = 10.0;
  static const double taxRate = 0.05;
}
