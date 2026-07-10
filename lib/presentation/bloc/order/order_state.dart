import 'package:equatable/equatable.dart';
import 'package:zomato_clone/domain/entities/order_entity.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrderCreated extends OrderState {
  final OrderEntity order;

  const OrderCreated({required this.order});

  @override
  List<Object?> get props => [order];
}

class OrderLoaded extends OrderState {
  final OrderEntity order;

  const OrderLoaded({required this.order});

  @override
  List<Object?> get props => [order];
}

class OrderUserOrdersLoaded extends OrderState {
  final List<OrderEntity> orders;

  const OrderUserOrdersLoaded({required this.orders});

  @override
  List<Object?> get props => [orders];
}

class OrderRestaurantOrdersLoaded extends OrderState {
  final List<OrderEntity> orders;

  const OrderRestaurantOrdersLoaded({required this.orders});

  @override
  List<Object?> get props => [orders];
}

class OrderRiderOrdersLoaded extends OrderState {
  final List<OrderEntity> orders;

  const OrderRiderOrdersLoaded({required this.orders});

  @override
  List<Object?> get props => [orders];
}

class OrderStatusUpdated extends OrderState {
  final String orderId;
  final String status;

  const OrderStatusUpdated({
    required this.orderId,
    required this.status,
  });

  @override
  List<Object?> get props => [orderId, status];
}

class OrderCancelled extends OrderState {
  final String orderId;

  const OrderCancelled({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class OrderTracking extends OrderState {
  final OrderEntity order;

  const OrderTracking({required this.order});

  @override
  List<Object?> get props => [order];
}

class OrderCouponApplied extends OrderState {
  final bool isValid;
  final String? message;

  const OrderCouponApplied({
    required this.isValid,
    this.message,
  });

  @override
  List<Object?> get props => [isValid, message];
}

class OrderRated extends OrderState {
  final String orderId;

  const OrderRated({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class OrderError extends OrderState {
  final String message;

  const OrderError({required this.message});

  @override
  List<Object?> get props => [message];
}
