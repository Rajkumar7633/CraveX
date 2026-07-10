import '../mock/mock_data.dart';
import '../models/order.dart';
import '../services/cart_service.dart';
import 'api_client.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final _orders = <Order>[];
  Order? _activeOrder;

  List<Order> get orderHistory => List.unmodifiable(_orders);
  Order? get activeOrder => _activeOrder;

  Future<Order> placeOrder({
    required String paymentMethod,
    required String addressId,
    String? instructions,
  }) async {
    final cart = CartService();
    final address = MockData.addresses.firstWhere((a) => a.id == addressId);
    final restaurant = MockData.restaurants.firstWhere(
      (r) => r.id == cart.restaurantId,
    );

    final order = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      userId: MockData.demoUser.id,
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      items: cart.items
          .map((i) => OrderLineItem(
                menuItemId: i.menuItemId,
                name: i.name,
                price: i.price,
                quantity: i.quantity,
                isVeg: i.isVeg,
                addOns: i.selectedAddOns,
              ))
          .toList(),
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      tax: cart.tax,
      platformFee: 5,
      packagingCharge: 10,
      discount: cart.discount,
      tip: cart.tip,
      total: cart.total,
      status: AppOrderStatus.placed,
      paymentMethod: paymentMethod,
      isPaid: paymentMethod != 'cod',
      deliveryAddress: address,
      specialInstructions: instructions,
      couponCode: cart.couponCode,
      estimatedDeliveryTime: DateTime.now().add(Duration(minutes: restaurant.deliveryTime)),
      createdAt: DateTime.now(),
      statusHistory: [
        OrderStatusStep(status: AppOrderStatus.placed, timestamp: DateTime.now()),
      ],
    );

    _orders.insert(0, order);
    _activeOrder = order;
    cart.clear();

    try {
      await ApiClient().orderDio.post('/orders', data: {
        'restaurantId': order.restaurantId,
        'items': order.items.map((i) => {
              'menuItemId': i.menuItemId,
              'quantity': i.quantity,
            }).toList(),
        'total': order.total,
      });
    } catch (_) {
      // Offline/mock mode — order stored locally
    }

    return order;
  }

  void updateOrderStatus(String orderId, String status) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    final order = _orders[idx];
    final updated = order.copyWith(
      status: status,
      riderId: status == AppOrderStatus.pickedUp ? MockData.demoRider.id : order.riderId,
      riderName: status == AppOrderStatus.pickedUp ? MockData.demoRider.name : order.riderName,
    );
    _orders[idx] = updated;
    if (_activeOrder?.id == orderId) _activeOrder = updated;
  }

  Order? getOrder(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return _activeOrder?.id == id ? _activeOrder : null;
    }
  }
}
