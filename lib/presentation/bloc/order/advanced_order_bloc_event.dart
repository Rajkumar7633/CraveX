part of 'advanced_order_bloc.dart';

abstract class AdvancedOrderEvent extends Equatable {
  const AdvancedOrderEvent();

  @override
  List<Object?> get props => [];
}

class CreateOrder extends AdvancedOrderEvent {
  final OrderRequest orderRequest;

  const CreateOrder(this.orderRequest);

  @override
  List<Object?> get props => [orderRequest];
}

class UpdateOrderStatus extends AdvancedOrderEvent {
  final String orderId;
  final String newStatus;
  final String eventId;

  const UpdateOrderStatus({
    required this.orderId,
    required this.newStatus,
    required this.eventId,
  });

  @override
  List<Object?> get props => [orderId, newStatus, eventId];
}

class CancelOrder extends AdvancedOrderEvent {
  final String orderId;
  final String reason;

  const CancelOrder({
    required this.orderId,
    required this.reason,
  });

  @override
  List<Object?> get props => [orderId, reason];
}

class TrackOrder extends AdvancedOrderEvent {
  final String orderId;

  const TrackOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class GetOrderHistory extends AdvancedOrderEvent {
  final String orderId;

  const GetOrderHistory(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
