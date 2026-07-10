import 'package:equatable/equatable.dart';
import 'package:zomato_clone/domain/entities/cart_entity.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {
  const CartInitial();
}

class CartLoading extends CartState {
  const CartLoading();
}

class CartLoaded extends CartState {
  final CartEntity cart;

  const CartLoaded({required this.cart});

  @override
  List<Object?> get props => [cart];
}

class CartItemAdded extends CartState {
  final CartEntity cart;

  const CartItemAdded({required this.cart});

  @override
  List<Object?> get props => [cart];
}

class CartItemUpdated extends CartState {
  final CartEntity cart;

  const CartItemUpdated({required this.cart});

  @override
  List<Object?> get props => [cart];
}

class CartItemRemoved extends CartState {
  final CartEntity cart;

  const CartItemRemoved({required this.cart});

  @override
  List<Object?> get props => [cart];
}

class CartCleared extends CartState {
  const CartCleared();
}

class CartCouponApplied extends CartState {
  final CartEntity cart;

  const CartCouponApplied({required this.cart});

  @override
  List<Object?> get props => [cart];
}

class CartCouponRemoved extends CartState {
  final CartEntity cart;

  const CartCouponRemoved({required this.cart});

  @override
  List<Object?> get props => [cart];
}

class CartDeliveryAddressSet extends CartState {
  final CartEntity cart;

  const CartDeliveryAddressSet({required this.cart});

  @override
  List<Object?> get props => [cart];
}

class CartError extends CartState {
  final String message;

  const CartError({required this.message});

  @override
  List<Object?> get props => [message];
}
