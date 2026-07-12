import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/order_api.dart';

final _api = OrderApi();

final myOrdersProvider = FutureProvider<List<Order>>(
  (ref) => _api.getMyOrders(),
);

final orderDetailProvider = FutureProvider.family<Order, String>(
  (ref, id) => _api.getOrderById(id),
);
