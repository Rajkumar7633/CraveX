import '../models/order.dart';
import 'api_client.dart';

class OrderApi {
  final _dio = ApiClient().orderDio;

  Future<Order> placeOrder(Map<String, dynamic> payload) async {
    final resp = await _dio.post('/orders', data: payload);
    return Order.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<Order>> getMyOrders() async {
    final resp = await _dio.get('/orders/my');
    final data = resp.data;
    List list;
    if (data is Map && data['orders'] != null) {
      list = data['orders'] as List;
    } else if (data is List) {
      list = data;
    } else {
      return [];
    }
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> getOrderById(String id) async {
    final resp = await _dio.get('/orders/$id');
    return Order.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> cancelOrder(String id) async {
    await _dio.post('/orders/$id/cancel');
  }
}
