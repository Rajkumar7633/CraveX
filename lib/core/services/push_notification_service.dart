import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:zomato_clone/core/utils/logger.dart';

class PushNotificationService {
  static PushNotificationService? _instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final StreamController<Map<String, dynamic>> _notificationController = StreamController.broadcast();

  PushNotificationService._();

  static PushNotificationService get instance {
    _instance ??= PushNotificationService._();
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info('User granted permission for notifications');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        AppLogger.info('User granted provisional permission for notifications');
      } else {
        AppLogger.info('User declined or has not accepted permission');
      }

      // Get FCM token
      final token = await _messaging.getToken();
      AppLogger.info('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Handle terminated state messages
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }

      // Subscribe to topics
      await subscribeToTopic('all_users');
    } catch (e) {
      AppLogger.error('Error initializing push notifications: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      AppLogger.error('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Error unsubscribing from topic $topic: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('Received foreground message: ${message.notification?.title}');
    _notificationController.add({
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
    });
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    AppLogger.info('Received background message: ${message.notification?.title}');
    _notificationController.add({
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'isBackground': true,
    });
  }

  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
}

class NotificationTypes {
  static const String orderUpdate = 'order_update';
  static const String orderAccepted = 'order_accepted';
  static const String orderRejected = 'order_rejected';
  static const String orderDelivered = 'order_delivered';
  static const String riderAssigned = 'rider_assigned';
  static const String paymentSuccess = 'payment_success';
  static const String paymentFailed = 'payment_failed';
  static const String promotion = 'promotion';
  static const String review = 'review';
  static const String system = 'system';
}

class NotificationHelper {
  static void showNotification(BuildContext context, Map<String, dynamic> notification) {
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (data.containsKey('orderId'))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to order tracking
              },
              child: const Text('View Order'),
            ),
        ],
      ),
    );
  }

  static String getNotificationIcon(String type) {
    switch (type) {
      case NotificationTypes.orderUpdate:
      case NotificationTypes.orderAccepted:
      case NotificationTypes.orderRejected:
      case NotificationTypes.orderDelivered:
        return '📦';
      case NotificationTypes.riderAssigned:
        return '🛵';
      case NotificationTypes.paymentSuccess:
        return '✅';
      case NotificationTypes.paymentFailed:
        return '❌';
      case NotificationTypes.promotion:
        return '🎉';
      case NotificationTypes.review:
        return '⭐';
      case NotificationTypes.system:
        return 'ℹ️';
      default:
        return '🔔';
    }
  }
}

class NotificationConfig {
  static const String serverKey = 'YOUR_FCM_SERVER_KEY';
  static const String apiUrl = 'https://fcm.googleapis.com/fcm/send';
  static const Duration notificationTimeout = Duration(seconds: 30);
}
