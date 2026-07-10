import 'package:dartz/dartz.dart';
import 'package:zomato_clone/core/error/failures.dart';
import 'package:zomato_clone/domain/entities/order_entity.dart';

abstract class OrderRepository {
  Future<Either<Failure, OrderEntity>> createOrder({
    required String restaurantId,
    required List<OrderItemEntity> items,
    required AddressEntity deliveryAddress,
    required String paymentMethod,
    String? couponCode,
    String? specialInstructions,
  });

  Future<Either<Failure, OrderEntity>> getOrderById({
    required String orderId,
  });

  Future<Either<Failure, List<OrderEntity>>> getUserOrders({
    String? status,
    int? page,
    int? limit,
  });

  Future<Either<Failure, List<OrderEntity>>> getRestaurantOrders({
    required String restaurantId,
    String? status,
    int? page,
    int? limit,
  });

  Future<Either<Failure, List<OrderEntity>>> getRiderOrders({
    required String riderId,
    String? status,
    int? page,
    int? limit,
  });

  Future<Either<Failure, bool>> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  });

  Future<Either<Failure, bool>> cancelOrder({
    required String orderId,
    String? reason,
  });

  Future<Either<Failure, bool>> trackOrder({
    required String orderId,
  });

  Stream<OrderEntity> orderStream({
    required String orderId,
  });

  Future<Either<Failure, bool>> applyCoupon({
    required String couponCode,
    required double orderValue,
  });

  Future<Either<Failure, bool>> rateOrder({
    required String orderId,
    required double rating,
    String? review,
  });
}
