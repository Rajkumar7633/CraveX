import 'package:equatable/equatable.dart';
import 'package:zomato_clone/domain/entities/cart_entity.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartLoadRequested extends CartEvent {
  const CartLoadRequested();
}

class CartAddItemRequested extends CartEvent {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? image;
  final List<AddonEntity>? selectedAddons;
  final VariantEntity? selectedVariant;

  const CartAddItemRequested({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    this.selectedAddons,
    this.selectedVariant,
  });

  @override
  List<Object?> get props => [
        menuItemId,
        name,
        price,
        quantity,
        image,
        selectedAddons,
        selectedVariant,
      ];
}

class CartUpdateItemRequested extends CartEvent {
  final String cartItemId;
  final int quantity;

  const CartUpdateItemRequested({
    required this.cartItemId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [cartItemId, quantity];
}

class CartRemoveItemRequested extends CartEvent {
  final String cartItemId;

  const CartRemoveItemRequested({required this.cartItemId});

  @override
  List<Object?> get props => [cartItemId];
}

class CartClearRequested extends CartEvent {
  const CartClearRequested();
}

class CartApplyCouponRequested extends CartEvent {
  final String couponCode;

  const CartApplyCouponRequested({required this.couponCode});

  @override
  List<Object?> get props => [couponCode];
}

class CartRemoveCouponRequested extends CartEvent {
  const CartRemoveCouponRequested();
}

class CartSetDeliveryAddressRequested extends CartEvent {
  final AddressEntity address;

  const CartSetDeliveryAddressRequested({required this.address});

  @override
  List<Object?> get props => [address];
}
