# WebSocket Setup Guide for CraveX

This guide explains how to implement real-time WebSocket features in the CraveX food delivery platform.

## Overview

WebSocket will be used for:
- **Order Tracking**: Real-time order status updates for customers
- **Rider Location**: Live rider location tracking
- **Restaurant Orders**: Real-time order notifications for restaurants
- **Chat System**: Real-time communication between users, riders, and restaurants
- **Live Dashboard**: Real-time analytics updates for admin

## Architecture

```
Client Apps (Flutter) ←→ WebSocket Service ←→ Kafka ←→ Microservices
```

## Go WebSocket Service Implementation

### Install Dependencies

```bash
go get github.com/gorilla/websocket
go get github.com/gorilla/mux
```

### WebSocket Hub Implementation

Create `backend/cmd/websocket-service/internal/hub/hub.go`:

```go
package hub

import (
	"encoding/json"
	"log"
	"sync"
)

type Message struct {
	Type      string      `json:"type"`
	Topic     string      `json:"topic"`
	Data      interface{} `json:"data"`
	Timestamp string      `json:"timestamp"`
}

type Client struct {
	ID     string
	UserID string
	Type   string // "customer", "restaurant", "rider", "admin"
	Send   chan Message
	Hub    *Hub
}

type Hub struct {
	clients    map[string]*Client
	broadcast  chan Message
	register   chan *Client
	unregister chan *Client
	mu         sync.RWMutex
}

func NewHub() *Hub {
	return &Hub{
		clients:    make(map[string]*Client),
		broadcast:  make(chan Message, 256),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client.ID] = client
			h.mu.Unlock()
			log.Printf("Client connected: %s (%s)", client.ID, client.Type)

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client.ID]; ok {
				delete(h.clients, client.ID)
				close(client.Send)
			}
			h.mu.Unlock()
			log.Printf("Client disconnected: %s", client.ID)

		case message := <-h.broadcast:
			h.mu.RLock()
			for _, client := range h.clients {
				select {
				case client.Send <- message:
				default:
					// Client channel full, disconnect
					h.unregister <- client
				}
			}
			h.mu.RUnlock()
		}
	}
}

func (h *Hub) SendToUser(userID string, message Message) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	for _, client := range h.clients {
		if client.UserID == userID {
			select {
			case client.Send <- message:
			default:
				h.unregister <- client
			}
		}
	}
}

func (h *Hub) SendToType(clientType string, message Message) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	for _, client := range h.clients {
		if client.Type == clientType {
			select {
			case client.Send <- message:
			default:
				h.unregister <- client
			}
		}
	}
}

func (h *Hub) SendToTopic(topic string, message Message) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	for _, client := range h.clients {
		if message.Topic == topic {
			select {
			case client.Send <- message:
			default:
				h.unregister <- client
			}
		}
	}
}

func (h *Hub) GetClientCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}
```

### WebSocket Handler Implementation

Create `backend/cmd/websocket-service/internal/handler/websocket_handler.go`:

```go
package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/zomato-clone/cmd/websocket-service/internal/hub"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Configure appropriately for production
	},
}

type WebSocketHandler struct {
	hub *hub.Hub
}

func NewWebSocketHandler(h *hub.Hub) *WebSocketHandler {
	return &WebSocketHandler{hub: h}
}

func (wh *WebSocketHandler) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	userID := r.URL.Query().Get("user_id")
	clientType := r.URL.Query().Get("type")

	if userID == "" || clientType == "" {
		http.Error(w, "Missing user_id or type parameter", http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	clientID := uuid.New().String()
	client := &hub.Client{
		ID:     clientID,
		UserID: userID,
		Type:   clientType,
		Send:   make(chan hub.Message, 256),
		Hub:    wh.hub,
	}

	wh.hub.register <- client

	// Start goroutines
	go client.writePump()
	go client.readPump(conn)
}

func (c *Client) readPump(conn *websocket.Conn) {
	defer func() {
		c.Hub.unregister <- c
		conn.Close()
	}()

	conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
			}
			break
		}

		var msg hub.Message
		if err := json.Unmarshal(message, &msg); err != nil {
			log.Printf("JSON unmarshal error: %v", err)
			continue
		}

		// Handle incoming messages
		c.handleMessage(msg)
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(54 * time.Second)
	defer func() {
		ticker.Stop()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			if !ok {
				return
			}

			data, err := json.Marshal(message)
			if err != nil {
				log.Printf("JSON marshal error: %v", err)
				continue
			}

			err = c.conn.WriteMessage(websocket.TextMessage, data)
			if err != nil {
				log.Printf("Write error: %v", err)
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (c *Client) handleMessage(msg hub.Message) {
	switch msg.Type {
	case "ping":
		c.Send <- hub.Message{
			Type:      "pong",
			Timestamp: time.Now().Format(time.RFC3339),
		}
	case "subscribe":
		// Handle topic subscription
		log.Printf("Client %s subscribed to topic: %s", c.ID, msg.Topic)
	case "unsubscribe":
		// Handle topic unsubscription
		log.Printf("Client %s unsubscribed from topic: %s", c.ID, msg.Topic)
	}
}
```

### WebSocket Service Main

Create `backend/cmd/websocket-service/main.go`:

```go
package main

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/zomato-clone/cmd/websocket-service/internal/handler"
	"github.com/zomato-clone/cmd/websocket-service/internal/hub"
)

func main() {
	// Initialize Hub
	h := hub.NewHub()
	go h.Run()

	// Initialize Handler
	wsHandler := handler.NewWebSocketHandler(h)

	// Setup Router
	router := mux.NewRouter()
	router.HandleFunc("/ws", wsHandler.HandleWebSocket).Methods("GET")

	// Start Server
	port := ":8080"
	log.Printf("WebSocket Service starting on port %s", port)
	log.Fatal(http.ListenAndServe(port, router))
}
```

## Event Types

### Order Events

```go
type OrderStatusUpdate struct {
	OrderID      string `json:"order_id"`
	Status       string `json:"status"`
	RiderID      string `json:"rider_id,omitempty"`
	RiderName    string `json:"rider_name,omitempty"`
	RiderPhone   string `json:"rider_phone,omitempty"`
	RiderLat     float64 `json:"rider_lat,omitempty"`
	RiderLng     float64 `json:"rider_lng,omitempty"`
	EstimatedETA string `json:"estimated_eta,omitempty"`
	Timestamp    string `json:"timestamp"`
}

type NewOrderEvent struct {
	OrderID      string  `json:"order_id"`
	UserID       string  `json:"user_id"`
	RestaurantID string `json:"restaurant_id"`
	TotalAmount  float64 `json:"total_amount"`
	DeliveryAddress string `json:"delivery_address"`
	Timestamp    string  `json:"timestamp"`
}
```

### Rider Events

```go
type RiderLocationUpdate struct {
	RiderID  string  `json:"rider_id"`
	OrderID  string  `json:"order_id"`
	Latitude float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Bearing  float64 `json:"bearing"`
	Speed    float64 `json:"speed"`
	Timestamp string `json:"timestamp"`
}

type RiderStatusUpdate struct {
	RiderID    string `json:"rider_id"`
	IsOnline   bool   `json:"is_online"`
	CurrentOrderID string `json:"current_order_id,omitempty"`
	Timestamp   string `json:"timestamp"`
}
```

### Restaurant Events

```go
type RestaurantOrderEvent struct {
	OrderID      string `json:"order_id"`
	CustomerName string `json:"customer_name"`
	Items        []OrderItem `json:"items"`
	TotalAmount  float64 `json:"total_amount"`
	DeliveryTime string `json:"delivery_time"`
	Timestamp    string `json:"timestamp"`
}
```

## Flutter WebSocket Integration

### WebSocket Service

Create `lib/core/services/websocket_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zomato_clone/core/config/app_config.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  
  String? _userId;
  String? _userType;
  bool _isConnected = false;

  WebSocketService._();

  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String userId, String userType) async {
    if (_isConnected) return;

    _userId = userId;
    _userType = userType;

    try {
      final uri = Uri.parse('${AppConfig.websocketUrl}?user_id=$userId&type=$userType');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          _messageController.add(data);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket disconnected');
          _isConnected = false;
        },
      );

      _isConnected = true;
      print('WebSocket connected');
    } catch (e) {
      print('WebSocket connection error: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }

  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void subscribe(String topic) {
    send({
      'type': 'subscribe',
      'topic': topic,
    });
  }

  void unsubscribe(String topic) {
    send({
      'type': 'unsubscribe',
      'topic': topic,
    });
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
```

### Order Tracking Implementation

Create `lib/core/services/order_tracking_service.dart`:

```dart
import 'dart:async';
import 'package:zomato_clone/core/services/websocket_service.dart';

class OrderTrackingService {
  final WebSocketService _wsService = WebSocketService.instance;
  final StreamController<OrderStatusUpdate> _statusController = StreamController.broadcast();
  final StreamController<RiderLocation> _locationController = StreamController.broadcast();

  Stream<OrderStatusUpdate> get statusUpdates => _statusController.stream;
  Stream<RiderLocation> get riderLocation => _locationController.stream;

  OrderTrackingService() {
    _initializeListeners();
  }

  void _initializeListeners() {
    _wsService.messageStream.listen((message) {
      switch (message['type']) {
        case 'order_status_update':
          final update = OrderStatusUpdate.fromJson(message['data']);
          _statusController.add(update);
          break;
        case 'rider_location_update':
          final location = RiderLocation.fromJson(message['data']);
          _locationController.add(location);
          break;
      }
    });
  }

  Future<void> trackOrder(String orderId) async {
    _wsService.subscribe('order:$orderId');
  }

  void stopTracking(String orderId) {
    _wsService.unsubscribe('order:$orderId');
  }

  void dispose() {
    _statusController.close();
    _locationController.close();
  }
}

class OrderStatusUpdate {
  final String orderId;
  final String status;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final double? riderLat;
  final double? riderLng;
  final String? estimatedEta;

  OrderStatusUpdate({
    required this.orderId,
    required this.status,
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.riderLat,
    this.riderLng,
    this.estimatedEta,
  });

  factory OrderStatusUpdate.fromJson(Map<String, dynamic> json) {
    return OrderStatusUpdate(
      orderId: json['order_id'],
      status: json['status'],
      riderId: json['rider_id'],
      riderName: json['rider_name'],
      riderPhone: json['rider_phone'],
      riderLat: json['rider_lat']?.toDouble(),
      riderLng: json['rider_lng']?.toDouble(),
      estimatedEta: json['estimated_eta'],
    );
  }
}

class RiderLocation {
  final String riderId;
  final String orderId;
  final double latitude;
  final double longitude;
  final double bearing;
  final double speed;

  RiderLocation({
    required this.riderId,
    required this.orderId,
    required this.latitude,
    required this.longitude,
    required this.bearing,
    required this.speed,
  });

  factory RiderLocation.fromJson(Map<String, dynamic> json) {
    return RiderLocation(
      riderId: json['rider_id'],
      orderId: json['order_id'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      bearing: json['bearing'].toDouble(),
      speed: json['speed'].toDouble(),
    );
  }
}
```

### Restaurant Order Updates

Create `lib/core/services/restaurant_order_service.dart`:

```dart
import 'dart:async';
import 'package:zomato_clone/core/services/websocket_service.dart';

class RestaurantOrderService {
  final WebSocketService _wsService = WebSocketService.instance;
  final StreamController<OrderEvent> _orderController = StreamController.broadcast();

  Stream<OrderEvent> get orderEvents => _orderController.stream;

  RestaurantOrderService() {
    _initializeListeners();
  }

  void _initializeListeners() {
    _wsService.messageStream.listen((message) {
      switch (message['type']) {
        case 'new_order':
          final order = OrderEvent.fromJson(message['data']);
          _orderController.add(order);
          break;
        case 'order_cancelled':
          final order = OrderEvent.fromJson(message['data']);
          _orderController.add(order);
          break;
      }
    });
  }

  Future<void> listenForOrders(String restaurantId) async {
    _wsService.subscribe('restaurant:$restaurantId');
  }

  void stopListening(String restaurantId) {
    _wsService.unsubscribe('restaurant:$restaurantId');
  }

  void dispose() {
    _orderController.close();
  }
}

class OrderEvent {
  final String orderId;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final double totalAmount;
  final String deliveryAddress;
  final String deliveryTime;

  OrderEvent({
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.deliveryTime,
  });

  factory OrderEvent.fromJson(Map<String, dynamic> json) {
    return OrderEvent(
      orderId: json['order_id'],
      customerId: json['user_id'],
      customerName: json['customer_name'],
      items: (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList(),
      totalAmount: json['total_amount'].toDouble(),
      deliveryAddress: json['delivery_address'],
      deliveryTime: json['delivery_time'],
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
    );
  }
}
```

## Environment Configuration

Add to `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  static const String websocketUrl = 'ws://localhost:8080/ws';
  static const int reconnectInterval = 5; // seconds
  static const int pingInterval = 30; // seconds
}
```

## Usage Examples

### Customer App - Order Tracking

```dart
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({required this.orderId});

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderTrackingService _trackingService = OrderTrackingService();

  @override
  void initState() {
    super.initState();
    _trackingService.trackOrder(widget.orderId);
  }

  @override
  void dispose() {
    _trackingService.stopTracking(widget.orderId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderStatusUpdate>(
      stream: _trackingService.statusUpdates,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final update = snapshot.data!;
        return OrderStatusWidget(status: update.status);
      },
    );
  }
}
```

### Restaurant App - Order Notifications

```dart
class RestaurantDashboardScreen extends StatefulWidget {
  @override
  _RestaurantDashboardScreenState createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  final RestaurantOrderService _orderService = RestaurantOrderService();

  @override
  void initState() {
    super.initState();
    _orderService.listenForOrders('REST123');
  }

  @override
  void dispose() {
    _orderService.stopListening('REST123');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderEvent>(
      stream: _orderService.orderEvents,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _DefaultDashboard();
        }

        final order = snapshot.data!;
        return _NewOrderNotification(order: order);
      },
    );
  }
}
```

## Best Practices

1. **Reconnection**: Implement automatic reconnection with exponential backoff
2. **Heartbeat**: Send periodic ping/pong messages to detect disconnections
3. **Error Handling**: Handle connection errors gracefully
4. **Message Validation**: Validate incoming messages before processing
5. **Topic Subscription**: Use topic-based subscriptions for efficient filtering
6. **Security**: Implement authentication and authorization
7. **Rate Limiting**: Limit message frequency to prevent abuse

## Production Considerations

1. **Scaling**: Use Redis pub/sub for horizontal scaling
2. **Load Balancing**: Use WebSocket-aware load balancer
3. **Monitoring**: Track connection counts and message throughput
4. **Security**: Use WSS (WebSocket Secure) with TLS
5. **Authentication**: Validate JWT tokens on connection
6. **Message Persistence**: Store undelivered messages for offline users
7. **Compression**: Enable message compression for large payloads

## Next Steps

- [ ] Implement Redis pub/sub for horizontal scaling
- [ ] Add message persistence for offline users
- [ ] Implement authentication middleware
- [ ] Add comprehensive error handling
- [ ] Set up monitoring and alerting
- [ ] Implement message compression
- [ ] Add integration tests for WebSocket flows
