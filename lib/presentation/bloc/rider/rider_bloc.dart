import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zomato_clone/core/error/failures.dart';
import 'package:zomato_clone/core/utils/logger.dart';
import 'package:zomato_clone/domain/entities/order_entity.dart';
import 'package:zomato_clone/domain/entities/rider_entity.dart';
import 'package:zomato_clone/domain/repositories/rider_repository.dart';
import 'package:zomato_clone/presentation/bloc/rider/rider_event.dart';
import 'package:zomato_clone/presentation/bloc/rider/rider_state.dart';

class RiderBloc extends Bloc<RiderEvent, RiderState> {
  final RiderRepository riderRepository;

  RiderBloc({required this.riderRepository}) : super(const RiderInitial()) {
    on<RiderLoadProfileRequested>(_onLoadProfile);
    on<RiderUpdateProfileRequested>(_onUpdateProfile);
    on<RiderUpdateLocationRequested>(_onUpdateLocation);
    on<RiderSetOnlineStatusRequested>(_onSetOnlineStatus);
    on<RiderSetAvailableStatusRequested>(_onSetAvailableStatus);
    on<RiderLoadAvailableOrdersRequested>(_onLoadAvailableOrders);
    on<RiderAcceptOrderRequested>(_onAcceptOrder);
    on<RiderRejectOrderRequested>(_onRejectOrder);
    on<RiderUpdateOrderStatusRequested>(_onUpdateOrderStatus);
    on<RiderLoadEarningsRequested>(_onLoadEarnings);
    on<RiderRequestWithdrawalRequested>(_onRequestWithdrawal);
    on<RiderLoadOrderHistoryRequested>(_onLoadOrderHistory);
  }

  Future<void> _onLoadProfile(
    RiderLoadProfileRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.getRiderProfile(
      riderId: event.riderId,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load rider profile failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (rider) {
        AppLogger.info('Rider profile loaded: ${rider.name}');
        emit(RiderProfileLoaded(rider: rider));
      },
    );
  }

  Future<void> _onUpdateProfile(
    RiderUpdateProfileRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.updateRiderProfile(
      riderId: event.riderId,
      data: event.data,
    );

    result.fold(
      (failure) {
        AppLogger.error('Update rider profile failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Rider profile updated');
        // Reload profile
        add(RiderLoadProfileRequested(riderId: event.riderId));
      },
    );
  }

  Future<void> _onUpdateLocation(
    RiderUpdateLocationRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.updateRiderLocation(
      riderId: event.riderId,
      latitude: event.latitude,
      longitude: event.longitude,
    );

    result.fold(
      (failure) {
        AppLogger.error('Update rider location failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Rider location updated');
        emit(RiderLocationUpdated(
          latitude: event.latitude,
          longitude: event.longitude,
        ));
      },
    );
  }

  Future<void> _onSetOnlineStatus(
    RiderSetOnlineStatusRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.setOnlineStatus(
      riderId: event.riderId,
      isOnline: event.isOnline,
    );

    result.fold(
      (failure) {
        AppLogger.error('Set online status failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Rider online status set to: ${event.isOnline}');
        emit(RiderOnlineStatusUpdated(isOnline: event.isOnline));
      },
    );
  }

  Future<void> _onSetAvailableStatus(
    RiderSetAvailableStatusRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.setAvailableStatus(
      riderId: event.riderId,
      isAvailable: event.isAvailable,
    );

    result.fold(
      (failure) {
        AppLogger.error('Set available status failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Rider available status set to: ${event.isAvailable}');
        emit(RiderAvailableStatusUpdated(isAvailable: event.isAvailable));
      },
    );
  }

  Future<void> _onLoadAvailableOrders(
    RiderLoadAvailableOrdersRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.getAvailableOrders(
      latitude: event.latitude,
      longitude: event.longitude,
      radius: event.radius,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load available orders failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (orders) {
        AppLogger.info('Loaded ${orders.length} available orders');
        emit(RiderAvailableOrdersLoaded(orders: orders));
      },
    );
  }

  Future<void> _onAcceptOrder(
    RiderAcceptOrderRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.acceptOrder(
      orderId: event.orderId,
      riderId: event.riderId,
    );

    result.fold(
      (failure) {
        AppLogger.error('Accept order failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Order accepted: ${event.orderId}');
        emit(RiderOrderAccepted(orderId: event.orderId));
      },
    );
  }

  Future<void> _onRejectOrder(
    RiderRejectOrderRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.rejectOrder(
      orderId: event.orderId,
      riderId: event.riderId,
    );

    result.fold(
      (failure) {
        AppLogger.error('Reject order failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Order rejected: ${event.orderId}');
        emit(RiderOrderRejected(orderId: event.orderId));
      },
    );
  }

  Future<void> _onUpdateOrderStatus(
    RiderUpdateOrderStatusRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.updateOrderStatus(
      orderId: event.orderId,
      status: event.status,
    );

    result.fold(
      (failure) {
        AppLogger.error('Update order status failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Order status updated: ${event.orderId} -> ${event.status}');
        emit(RiderOrderStatusUpdated(
          orderId: event.orderId,
          status: event.status,
        ));
      },
    );
  }

  Future<void> _onLoadEarnings(
    RiderLoadEarningsRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.getEarnings(
      riderId: event.riderId,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load earnings failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (earnings) {
        AppLogger.info('Loaded ${earnings.length} earnings records');
        emit(RiderEarningsLoaded(earnings: earnings));
      },
    );
  }

  Future<void> _onRequestWithdrawal(
    RiderRequestWithdrawalRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.requestWithdrawal(
      riderId: event.riderId,
      amount: event.amount,
    );

    result.fold(
      (failure) {
        AppLogger.error('Request withdrawal failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Withdrawal requested: \$${event.amount}');
        emit(const RiderWithdrawalRequested());
      },
    );
  }

  Future<void> _onLoadOrderHistory(
    RiderLoadOrderHistoryRequested event,
    Emitter<RiderState> emit,
  ) async {
    emit(const RiderLoading());
    final result = await riderRepository.getRiderOrderHistory(
      riderId: event.riderId,
      status: event.status,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load order history failed: ${failure.message}');
        emit(RiderError(message: failure.message));
      },
      (orders) {
        AppLogger.info('Loaded ${orders.length} order history records');
        emit(RiderOrderHistoryLoaded(orders: orders));
      },
    );
  }
}
