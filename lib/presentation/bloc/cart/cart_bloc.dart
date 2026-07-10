import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zomato_clone/core/error/failures.dart';
import 'package:zomato_clone/core/utils/logger.dart';
import 'package:zomato_clone/domain/entities/cart_entity.dart';
import 'package:zomato_clone/domain/repositories/cart_repository.dart';
import 'package:zomato_clone/presentation/bloc/cart/cart_event.dart';
import 'package:zomato_clone/presentation/bloc/cart/cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository cartRepository;

  CartBloc({required this.cartRepository}) : super(const CartInitial()) {
    on<CartLoadRequested>(_onLoadCart);
    on<CartAddItemRequested>(_onAddItem);
    on<CartUpdateItemRequested>(_onUpdateItem);
    on<CartRemoveItemRequested>(_onRemoveItem);
    on<CartClearRequested>(_onClearCart);
    on<CartApplyCouponRequested>(_onApplyCoupon);
    on<CartRemoveCouponRequested>(_onRemoveCoupon);
    on<CartSetDeliveryAddressRequested>(_onSetDeliveryAddress);
  }

  Future<void> _onLoadCart(
    CartLoadRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    final result = await cartRepository.getCart();

    result.fold(
      (failure) {
        AppLogger.error('Load cart failed: ${failure.message}');
        emit(CartError(message: failure.message));
      },
      (cart) {
        AppLogger.info('Cart loaded with ${cart.items.length} items');
        emit(CartLoaded(cart: cart));
      },
    );
  }

  Future<void> _onAddItem(
    CartAddItemRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    final result = await cartRepository.addToCart(
      menuItemId: event.menuItemId,
      name: event.name,
      price: event.price,
      quantity: event.quantity,
      image: event.image,
      selectedAddons: event.selectedAddons,
      selectedVariant: event.selectedVariant,
    );

    result.fold(
      (failure) {
        AppLogger.error('Add item to cart failed: ${failure.message}');
        emit(CartError(message: failure.message));
      },
      (cart) {
        AppLogger.info('Item added to cart: ${event.name}');
        emit(CartItemAdded(cart: cart));
      },
    );
  }

  Future<void> _onUpdateItem(
    CartUpdateItemRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    final result = await cartRepository.updateCartItem(
      cartItemId: event.cartItemId,
      quantity: event.quantity,
    );

    result.fold(
      (failure) {
        AppLogger.error('Update cart item failed: ${failure.message}');
        emit(CartError(message: failure.message));
      },
      (cart) {
        AppLogger.info('Cart item updated: ${event.cartItemId}');
        emit(CartItemUpdated(cart: cart));
      },
    );
  }

  Future<void> _onRemoveItem(
    CartRemoveItemRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    final result = await cartRepository.removeFromCart(
      cartItemId: event.cartItemId,
    );

    result.fold(
      (failure) {
        AppLogger.error('Remove cart item failed: ${failure.message}');
        emit(CartError(message: failure.message));
      },
      (cart) {
        AppLogger.info('Cart item removed: ${event.cartItemId}');
        emit(CartItemRemoved(cart: cart));
      },
    );
  }

  Future<void> _onClearCart(
    CartClearRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    final result = await cartRepository.clearCart();

    result.fold(
      (failure) {
        AppLogger.error('Clear cart failed: ${failure.message}');
        emit(CartError(message: failure.message));
      },
      (cart) {
        AppLogger.info('Cart cleared');
        emit(const CartCleared());
      },
    );
  }

  Future<void> _onApplyCoupon(
    CartApplyCouponRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    final result = await cartRepository.applyCoupon(
      couponCode: event.couponCode,
    );

    result.fold(
      (failure) {
        AppLogger.error('Apply coupon failed: ${failure.message}');
        emit(CartError(message: failure.message));
      },
      (cart) {
        AppLogger.info('Coupon applied: ${event.couponCode}');
        emit(CartCouponApplied(cart: cart));
      },
    );
  }

  Future<void> _onRemoveCoupon(
    CartRemoveCouponRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    final result = await cartRepository.removeCoupon();

    result.fold(
      (failure) {
        AppLogger.error('Remove coupon failed: ${failure.message}');
        emit(CartError(message: failure.message));
      },
      (cart) {
        AppLogger.info('Coupon removed');
        emit(CartCouponRemoved(cart: cart));
      },
    );
  }

  Future<void> _onSetDeliveryAddress(
    CartSetDeliveryAddressRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    final result = await cartRepository.setDeliveryAddress(
      address: event.address,
    );

    result.fold(
      (failure) {
        AppLogger.error('Set delivery address failed: ${failure.message}');
        emit(CartError(message: failure.message));
      },
      (cart) {
        AppLogger.info('Delivery address set');
        emit(CartDeliveryAddressSet(cart: cart));
      },
    );
  }
}
