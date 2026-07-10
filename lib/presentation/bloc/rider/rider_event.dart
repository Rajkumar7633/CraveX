import 'package:equatable/equatable.dart';

abstract class RiderEvent extends Equatable {
  const RiderEvent();

  @override
  List<Object?> get props => [];
}

class RiderLoadProfileRequested extends RiderEvent {
  final String riderId;

  const RiderLoadProfileRequested({required this.riderId});

  @override
  List<Object?> get props => [riderId];
}

class RiderUpdateProfileRequested extends RiderEvent {
  final String riderId;
  final Map<String, dynamic> data;

  const RiderUpdateProfileRequested({
    required this.riderId,
    required this.data,
  });

  @override
  List<Object?> get props => [riderId, data];
}

class RiderUpdateLocationRequested extends RiderEvent {
  final String riderId;
  final double latitude;
  final double longitude;

  const RiderUpdateLocationRequested({
    required this.riderId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [riderId, latitude, longitude];
}

class RiderSetOnlineStatusRequested extends RiderEvent {
  final String riderId;
  final bool isOnline;

  const RiderSetOnlineStatusRequested({
    required this.riderId,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [riderId, isOnline];
}

class RiderSetAvailableStatusRequested extends RiderEvent {
  final String riderId;
  final bool isAvailable;

  const RiderSetAvailableStatusRequested({
    required this.riderId,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [riderId, isAvailable];
}

class RiderLoadAvailableOrdersRequested extends RiderEvent {
  final double latitude;
  final double longitude;
  final double radius;

  const RiderLoadAvailableOrdersRequested({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  @override
  List<Object?> get props => [latitude, longitude, radius];
}

class RiderAcceptOrderRequested extends RiderEvent {
  final String orderId;
  final String riderId;

  const RiderAcceptOrderRequested({
    required this.orderId,
    required this.riderId,
  });

  @override
  List<Object?> get props => [orderId, riderId];
}

class RiderRejectOrderRequested extends RiderEvent {
  final String orderId;
  final String riderId;

  const RiderRejectOrderRequested({
    required this.orderId,
    required this.riderId,
  });

  @override
  List<Object?> get props => [orderId, riderId];
}

class RiderUpdateOrderStatusRequested extends RiderEvent {
  final String orderId;
  final String status;

  const RiderUpdateOrderStatusRequested({
    required this.orderId,
    required this.status,
  });

  @override
  List<Object?> get props => [orderId, status];
}

class RiderLoadEarningsRequested extends RiderEvent {
  final String riderId;
  final DateTime? startDate;
  final DateTime? endDate;

  const RiderLoadEarningsRequested({
    required this.riderId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [riderId, startDate, endDate];
}

class RiderRequestWithdrawalRequested extends RiderEvent {
  final String riderId;
  final double amount;

  const RiderRequestWithdrawalRequested({
    required this.riderId,
    required this.amount,
  });

  @override
  List<Object?> get props => [riderId, amount];
}

class RiderLoadOrderHistoryRequested extends RiderEvent {
  final String riderId;
  final String? status;
  final int? page;
  final int? limit;

  const RiderLoadOrderHistoryRequested({
    required this.riderId,
    this.status,
    this.page,
    this.limit,
  });

  @override
  List<Object?> get props => [riderId, status, page, limit];
}
