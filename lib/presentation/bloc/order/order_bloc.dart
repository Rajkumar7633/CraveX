import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zomato_clone/core/error/failures.dart';
import 'package:zomato_clone/core/utils/logger.dart';
import 'package:zomato_clone/domain/entities/order_entity.dart';
import 'package:zomato_clone/domain/repositories/order_repository.dart';
import 'package:zomato_clone/presentation/bloc/order/order_event.dart';
import 'package:zomato_clone/presentation/bloc/order/order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository orderRepository;

  OrderBloc({required this.orderRepository}) : super(const OrderInitial()) {
    on<OrderCreateRequested>(_onCreateOrder);
    on<OrderLoadByIdRequested>(_onLoadOrderById);
    on<OrderLoadUserOrdersRequested>(_onLoadUserOrders);
    on<OrderLoadRestaurantOrdersRequested>(_onLoadRestaurantOrders);
    on<OrderLoadRiderOrdersRequested>(_onLoadRiderOrders);
    on<OrderUpdateStatusRequested>(_onUpdateOrderStatus);
    on<OrderCancelRequested>(_onCancelOrder);
    on<OrderTrackRequested>(_onTrackOrder);
    on<OrderApplyCouponRequested>(_onApplyCoupon);
    on<OrderRateRequested>(_onRateOrder);
  }

  Future<void> _onCreateOrder(
    OrderCreateRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await orderRepository.createOrder(
      restaurantId: event.restaurantId,
      items: event.items,
      deliveryAddress: event.deliveryAddress,
      paymentMethod: event.paymentMethod,
      couponCode: event.couponCode,
      specialInstructions: event.specialInstructions,
    );

    result.fold(
      (failure) {
        AppLogger.error('Create order failed: ${failure.message}');
        emit(OrderError(message: failure.message));
      },
      (order) {
        AppLogger.info('Order created successfully: ${order.id}');
        emit(OrderCreated(order: order));
      },
    );
  }

  Future<void> _onLoadOrderById(
    OrderLoadByIdRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await orderRepository.getOrderById(orderId: event.orderId);

    result.fold(
      (failure) {
        AppLogger.error('Load order failed: ${failure.message}');
        emit(OrderError(message: failure.message));
      },
      (order) {
        AppLogger.info('Order loaded: ${order.id}');
        emit(OrderLoaded(order: order));
      },
    );
  }

  Future<void> _onLoadUserOrders(
    OrderLoadUserOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await orderRepository.getUserOrders(
      status: event.status,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load user orders failed: ${failure.message}');
        emit(OrderError(message: failure.message));
      },
      (orders) {
        AppLogger.info('Loaded ${orders.length} user orders');
        emit(OrderUserOrdersLoaded(orders: orders));
      },
    );
  }

  Future<void> _onLoadRestaurantOrders(
    OrderLoadRestaurantOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await orderRepository.getRestaurantOrders(
      restaurantId: event.restaurantId,
      status: event.status,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load restaurant orders failed: ${failure.message}');
        emit(OrderError(message: failure.message));
      },
      (orders) {
        AppLogger.info('Loaded ${orders.length} restaurant orders');
        emit(OrderRestaurantOrdersLoaded(orders: orders));
      },
    );
  }

  Future<void> _onLoadRiderOrders(
    OrderLoadRiderOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await orderRepository.getRiderOrders(
      riderId: event.riderId,
      status: event.status,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load rider orders failed: ${failure.message}');
        emit(OrderError(message: failure.message));
      },
      (orders) {
        AppLogger.info('Loaded ${orders.length} rider orders');
        emit(OrderRiderOrdersLoaded(orders: orders));
      },
    );
  }

  Future<void> _onUpdateOrderStatus(
    OrderUpdateStatusRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await orderRepository.updateOrderStatus(
      orderId: event.orderId,
      status: event.status,
      note: event.note,
    );

    result.fold(
      (failure) {
        AppLogger.error('Update order status failed: ${failure.message}');
        emit(OrderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Order status updated: ${event.orderId} -> ${event.status}');
        emit(OrderStatusUpdated(
          orderId: event.orderId,
          status: event.status,
        ));
      },
    );
  }

  Future<void> _onCancelOrder(
    OrderCancelRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await orderRepository.cancelOrder(
      orderId: event.orderId,
      reason: event.reason,
    );

    result.fold(
      (failure) {
        AppLogger.error('Cancel order failed: ${failure.message}');
        emit(OrderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Order cancelled: ${event.orderId}');
        emit(OrderCancelled(orderId: event.orderId));
      },
    );
  }

  Future<void> _onTrackOrder(
    OrderTrackRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await orderRepository.trackOrder(orderId: event.orderId);

    result.fold(
      (failure) {
        AppLogger.error('Track order failed: ${failure.message}');
        emit(OrderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Tracking order: ${event.orderId}');
        // Load the order details
        add(OrderLoadByIdRequested(orderId: event.orderId));
      },
    );
  }

  Future<void> _onApplyCoupon(
    OrderApplyCouponRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await orderRepository.applyCoupon(
      couponCode: event.couponCode,
      orderValue: event.orderValue,
    );

    result.fold(
      (failure) {
        AppLogger.error('Apply coupon failed: ${failure.message}');
        emit(OrderCouponApplied(
          isValid: false,
          message: failure.message,
        ));
      },
      (success) {
        AppLogger.info('Coupon applied successfully: ${event.couponCode}');
        emit(const OrderCouponApplied(
          isValid: true,
          message: 'Coupon applied successfully',
        ));
      },
    );
  }

  Future<void> _onRateOrder(
    OrderRateRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await orderRepository.rateOrder(
      orderId: event.orderId,
      rating: event.rating,
      review: event.review,
    );

    result.fold(
      (failure) {
        AppLogger.error('Rate order failed: ${failure.message}');
        emit(OrderError(message: failure.message));
      },
      (success) {
        AppLogger.info('Order rated: ${event.orderId} -> ${event.rating}');
        emit(OrderRated(orderId: event.orderId));
      },
    );
  }
}
