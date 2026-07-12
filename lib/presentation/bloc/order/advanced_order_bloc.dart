import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zomato_clone/domain/entities/order.dart';
import 'package:zomato_clone/domain/repositories/order_repository.dart';

// Advanced Order BLoC with state machine integration
part 'advanced_order_bloc_event.dart';
part 'advanced_order_bloc_state.dart';

class AdvancedOrderBloc extends Bloc<AdvancedOrderEvent, AdvancedOrderState> {
  final OrderRepository orderRepository;

  AdvancedOrderBloc(this.orderRepository) : super(const AdvancedOrderInitial()) {
    on<CreateOrder>(_onCreateOrder);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<CancelOrder>(_onCancelOrder);
    on<TrackOrder>(_onTrackOrder);
    on<GetOrderHistory>(_onGetOrderHistory);
  }

  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<AdvancedOrderState> emit,
  ) async {
    emit(const AdvancedOrderLoading());
    try {
      final order = await orderRepository.createOrder(event.orderRequest);
      emit(AdvancedOrderCreated(order));
    } catch (e) {
      emit(AdvancedOrderError(e.toString()));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<AdvancedOrderState> emit,
  ) async {
    try {
      await orderRepository.updateOrderStatus(
        event.orderId,
        event.newStatus,
        event.eventId,
      );
      emit(AdvancedOrderStatusUpdated(event.newStatus));
    } catch (e) {
      emit(AdvancedOrderError(e.toString()));
    }
  }

  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<AdvancedOrderState> emit,
  ) async {
    try {
      await orderRepository.cancelOrder(event.orderId, event.reason);
      emit(const AdvancedOrderCancelled());
    } catch (e) {
      emit(AdvancedOrderError(e.toString()));
    }
  }

  Future<void> _onTrackOrder(
    TrackOrder event,
    Emitter<AdvancedOrderState> emit,
  ) async {
    try {
      final order = await orderRepository.getOrderById(event.orderId);
      emit(AdvancedOrderTracking(order));
    } catch (e) {
      emit(AdvancedOrderError(e.toString()));
    }
  }

  Future<void> _onGetOrderHistory(
    GetOrderHistory event,
    Emitter<AdvancedOrderState> emit,
  ) async {
    try {
      final history = await orderRepository.getOrderHistory(event.orderId);
      emit(AdvancedOrderHistoryLoaded(history));
    } catch (e) {
      emit(AdvancedOrderError(e.toString()));
    }
  }
}
