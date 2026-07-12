part of 'advanced_order_bloc.dart';

abstract class AdvancedOrderState extends Equatable {
  const AdvancedOrderState();

  @override
  List<Object?> get props => [];
}

class AdvancedOrderInitial extends AdvancedOrderState {
  const AdvancedOrderInitial();
}

class AdvancedOrderLoading extends AdvancedOrderState {
  const AdvancedOrderLoading();
}

class AdvancedOrderCreated extends AdvancedOrderState {
  final Order order;

  const AdvancedOrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}

class AdvancedOrderStatusUpdated extends AdvancedOrderState {
  final String status;

  const AdvancedOrderStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];
}

class AdvancedOrderCancelled extends AdvancedOrderState {
  const AdvancedOrderCancelled();
}

class AdvancedOrderTracking extends AdvancedOrderState {
  final Order order;

  const AdvancedOrderTracking(this.order);

  @override
  List<Object?> get props => [order];
}

class AdvancedOrderHistoryLoaded extends AdvancedOrderState {
  final List<OrderEvent> history;

  const AdvancedOrderHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class AdvancedOrderError extends AdvancedOrderState {
  final String message;

  const AdvancedOrderError(this.message);

  @override
  List<Object?> get props => [message];
}
