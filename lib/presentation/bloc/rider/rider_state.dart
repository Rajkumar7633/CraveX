import 'package:equatable/equatable.dart';
import 'package:zomato_clone/domain/entities/order_entity.dart';
import 'package:zomato_clone/domain/entities/rider_entity.dart';

abstract class RiderState extends Equatable {
  const RiderState();

  @override
  List<Object?> get props => [];
}

class RiderInitial extends RiderState {
  const RiderInitial();
}

class RiderLoading extends RiderState {
  const RiderLoading();
}

class RiderProfileLoaded extends RiderState {
  final RiderEntity rider;

  const RiderProfileLoaded({required this.rider});

  @override
  List<Object?> get props => [rider];
}

class RiderProfileUpdated extends RiderState {
  final RiderEntity rider;

  const RiderProfileUpdated({required this.rider});

  @override
  List<Object?> get props => [rider];
}

class RiderLocationUpdated extends RiderState {
  final double latitude;
  final double longitude;

  const RiderLocationUpdated({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

class RiderOnlineStatusUpdated extends RiderState {
  final bool isOnline;

  const RiderOnlineStatusUpdated({required this.isOnline});

  @override
  List<Object?> get props => [isOnline];
}

class RiderAvailableStatusUpdated extends RiderState {
  final bool isAvailable;

  const RiderAvailableStatusUpdated({required this.isAvailable});

  @override
  List<Object?> get props => [isAvailable];
}

class RiderAvailableOrdersLoaded extends RiderState {
  final List<OrderEntity> orders;

  const RiderAvailableOrdersLoaded({required this.orders});

  @override
  List<Object?> get props => [orders];
}

class RiderOrderAccepted extends RiderState {
  final String orderId;

  const RiderOrderAccepted({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class RiderOrderRejected extends RiderState {
  final String orderId;

  const RiderOrderRejected({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class RiderOrderStatusUpdated extends RiderState {
  final String orderId;
  final String status;

  const RiderOrderStatusUpdated({
    required this.orderId,
    required this.status,
  });

  @override
  List<Object?> get props => [orderId, status];
}

class RiderEarningsLoaded extends RiderState {
  final List<EarningEntity> earnings;

  const RiderEarningsLoaded({required this.earnings});

  @override
  List<Object?> get props => [earnings];
}

class RiderWithdrawalRequested extends RiderState {
  const RiderWithdrawalRequested();
}

class RiderOrderHistoryLoaded extends RiderState {
  final List<OrderEntity> orders;

  const RiderOrderHistoryLoaded({required this.orders});

  @override
  List<Object?> get props => [orders];
}

class RiderError extends RiderState {
  final String message;

  const RiderError({required this.message});

  @override
  List<Object?> get props => [message];
}
