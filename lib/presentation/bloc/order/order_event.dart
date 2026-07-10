import 'package:equatable/equatable.dart';
import 'package:zomato_clone/domain/entities/order_entity.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class OrderCreateRequested extends OrderEvent {
  final String restaurantId;
  final List<OrderItemEntity> items;
  final AddressEntity deliveryAddress;
  final String paymentMethod;
  final String? couponCode;
  final String? specialInstructions;

  const OrderCreateRequested({
    required this.restaurantId,
    required this.items,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.couponCode,
    this.specialInstructions,
  });

  @override
  List<Object?> get props => [
        restaurantId,
        items,
        deliveryAddress,
        paymentMethod,
        couponCode,
        specialInstructions,
      ];
}

class OrderLoadByIdRequested extends OrderEvent {
  final String orderId;

  const OrderLoadByIdRequested({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class OrderLoadUserOrdersRequested extends OrderEvent {
  final String? status;
  final int? page;
  final int? limit;

  const OrderLoadUserOrdersRequested({
    this.status,
    this.page,
    this.limit,
  });

  @override
  List<Object?> get props => [status, page, limit];
}

class OrderLoadRestaurantOrdersRequested extends OrderEvent {
  final String restaurantId;
  final String? status;
  final int? page;
  final int? limit;

  const OrderLoadRestaurantOrdersRequested({
    required this.restaurantId,
    this.status,
    this.page,
    this.limit,
  });

  @override
  List<Object?> get props => [restaurantId, status, page, limit];
}

class OrderLoadRiderOrdersRequested extends OrderEvent {
  final String riderId;
  final String? status;
  final int? page;
  final int? limit;

  const OrderLoadRiderOrdersRequested({
    required this.riderId,
    this.status,
    this.page,
    this.limit,
  });

  @override
  List<Object?> get props => [riderId, status, page, limit];
}

class OrderUpdateStatusRequested extends OrderEvent {
  final String orderId;
  final String status;
  final String? note;

  const OrderUpdateStatusRequested({
    required this.orderId,
    required this.status,
    this.note,
  });

  @override
  List<Object?> get props => [orderId, status, note];
}

class OrderCancelRequested extends OrderEvent {
  final String orderId;
  final String? reason;

  const OrderCancelRequested({
    required this.orderId,
    this.reason,
  });

  @override
  List<Object?> get props => [orderId, reason];
}

class OrderTrackRequested extends OrderEvent {
  final String orderId;

  const OrderTrackRequested({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class OrderApplyCouponRequested extends OrderEvent {
  final String couponCode;
  final double orderValue;

  const OrderApplyCouponRequested({
    required this.couponCode,
    required this.orderValue,
  });

  @override
  List<Object?> get props => [couponCode, orderValue];
}

class OrderRateRequested extends OrderEvent {
  final String orderId;
  final double rating;
  final String? review;

  const OrderRateRequested({
    required this.orderId,
    required this.rating,
    this.review,
  });

  @override
  List<Object?> get props => [orderId, rating, review];
}
