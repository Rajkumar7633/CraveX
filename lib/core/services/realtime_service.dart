import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zomato_clone/core/utils/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeService {
  static RealtimeService? _instance;
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final Map<String, List<void Function(Map<String, dynamic>)>> _subscriptions = {};

  RealtimeService._();

  static RealtimeService get instance {
    _instance ??= RealtimeService._();
    return _instance!;
  }

  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
      AppLogger.info('WebSocket connected to $url');
    } catch (e) {
      AppLogger.error('WebSocket connection failed: $e');
      rethrow;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    AppLogger.info('WebSocket disconnected');
  }

  void subscribe(String event, void Function(Map<String, dynamic>) callback) {
    if (!_subscriptions.containsKey(event)) {
      _subscriptions[event] = [];
    }
    _subscriptions[event]!.add(callback);
    AppLogger.info('Subscribed to event: $event');
  }

  void unsubscribe(String event, void Function(Map<String, dynamic>) callback) {
    if (_subscriptions.containsKey(event)) {
      _subscriptions[event]!.remove(callback);
      if (_subscriptions[event]!.isEmpty) {
        _subscriptions.remove(event);
      }
    }
    AppLogger.info('Unsubscribed from event: $event');
  }

  void emit(String event, Map<String, dynamic> data) {
    final message = {
      'event': event,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _channel?.sink.add(message);
    AppLogger.info('Emitted event: $event');
  }

  void _handleMessage(dynamic message) {
    try {
      final data = message as Map<String, dynamic>;
      final event = data['event'] as String?;
      final payload = data['data'] as Map<String, dynamic>?;

      if (event != null && payload != null) {
        _messageController.add(payload);
        if (_subscriptions.containsKey(event)) {
          for (final callback in _subscriptions[event]!) {
            callback(payload);
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error handling WebSocket message: $e');
    }
  }

  void _handleError(dynamic error) {
    AppLogger.error('WebSocket error: $error');
  }

  void _handleDone() {
    AppLogger.info('WebSocket connection closed');
    _channel = null;
  }

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool get isConnected => _channel != null;
}

class OrderTrackingService {
  final RealtimeService _realtimeService = RealtimeService.instance;

  void subscribeToOrderUpdates(String orderId, void Function(Map<String, dynamic>) onUpdate) {
    _realtimeService.subscribe('order_$orderId', onUpdate);
  }

  void unsubscribeFromOrderUpdates(String orderId, void Function(Map<String, dynamic>) onUpdate) {
    _realtimeService.unsubscribe('order_$orderId', onUpdate);
  }

  void sendOrderStatusUpdate(String orderId, String status, Map<String, dynamic>? additionalData) {
    _realtimeService.emit('order_status_update', {
      'orderId': orderId,
      'status': status,
      ...?additionalData,
    });
  }
}

class LocationTrackingService {
  final RealtimeService _realtimeService = RealtimeService.instance;

  void subscribeToRiderLocation(String riderId, void Function(Map<String, dynamic>) onLocationUpdate) {
    _realtimeService.subscribe('rider_location_$riderId', onLocationUpdate);
  }

  void unsubscribeFromRiderLocation(String riderId, void Function(Map<String, dynamic>) onLocationUpdate) {
    _realtimeService.unsubscribe('rider_location_$riderId', onLocationUpdate);
  }

  void broadcastLocation(String riderId, double latitude, double longitude) {
    _realtimeService.emit('location_update', {
      'riderId': riderId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

class ChatService {
  final RealtimeService _realtimeService = RealtimeService.instance;

  void subscribeToChat(String orderId, void Function(Map<String, dynamic>) onMessage) {
    _realtimeService.subscribe('chat_$orderId', onMessage);
  }

  void unsubscribeFromChat(String orderId, void Function(Map<String, dynamic>) onMessage) {
    _realtimeService.unsubscribe('chat_$orderId', onMessage);
  }

  void sendMessage(String orderId, String senderId, String message, String senderType) {
    _realtimeService.emit('chat_message', {
      'orderId': orderId,
      'senderId': senderId,
      'senderType': senderType, // 'user', 'restaurant', 'rider'
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

class NotificationService {
  final RealtimeService _realtimeService = RealtimeService.instance;

  void subscribeToNotifications(String userId, void Function(Map<String, dynamic>) onNotification) {
    _realtimeService.subscribe('notifications_$userId', onNotification);
  }

  void unsubscribeFromNotifications(String userId, void Function(Map<String, dynamic>) onNotification) {
    _realtimeService.unsubscribe('notifications_$userId', onNotification);
  }

  void sendNotification(String userId, String title, String body, Map<String, dynamic>? data) {
    _realtimeService.emit('notification', {
      'userId': userId,
      'title': title,
      'body': body,
      'data': data ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

class RealtimeConfig {
  static const String websocketUrl = 'wss://api.zomato-clone.com/ws';
  static const Duration reconnectInterval = Duration(seconds: 5);
  static const int maxReconnectAttempts = 10;
}
