import 'package:equatable/equatable.dart';

class CartEntity extends Equatable {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final List<CartItemEntity> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final String? couponCode;
  final double? couponDiscount;
  final AddressEntity? deliveryAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CartEntity({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.discount,
    required this.total,
    this.couponCode,
    this.couponDiscount,
    this.deliveryAddress,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        restaurantId,
        restaurantName,
        items,
        subtotal,
        deliveryFee,
        tax,
        discount,
        total,
        couponCode,
        couponDiscount,
        deliveryAddress,
        createdAt,
        updatedAt,
      ];
}

class CartItemEntity extends Equatable {
  final String id;
  final String menuItemId;
  final String name;
  final String? image;
  final double price;
  final int quantity;
  final List<AddonEntity>? selectedAddons;
  final VariantEntity? selectedVariant;

  const CartItemEntity({
    required this.id,
    required this.menuItemId,
    required this.name,
    this.image,
    required this.price,
    required this.quantity,
    this.selectedAddons,
    this.selectedVariant,
  });

  @override
  List<Object?> get props => [
        id,
        menuItemId,
        name,
        image,
        price,
        quantity,
        selectedAddons,
        selectedVariant,
      ];
}

class AddonEntity extends Equatable {
  final String id;
  final String name;
  final double price;

  const AddonEntity({
    required this.id,
    required this.name,
    required this.price,
  });

  @override
  List<Object?> get props => [id, name, price];
}

class VariantEntity extends Equatable {
  final String id;
  final String name;
  final double price;

  const VariantEntity({
    required this.id,
    required this.name,
    required this.price,
  });

  @override
  List<Object?> get props => [id, name, price];
}

class AddressEntity extends Equatable {
  final String id;
  final String label;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final String? landmark;

  const AddressEntity({
    required this.id,
    required this.label,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.landmark,
  });

  @override
  List<Object?> get props => [
        id,
        label,
        addressLine1,
        addressLine2,
        city,
        state,
        pincode,
        latitude,
        longitude,
        landmark,
      ];
}
