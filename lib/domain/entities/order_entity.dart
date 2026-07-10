import 'package:equatable/equatable.dart';

class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantImage;
  final List<OrderItemEntity> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final String status;
  final String paymentMethod;
  final String? paymentId;
  final bool isPaid;
  final AddressEntity deliveryAddress;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final String? riderLocation;
  final List<OrderStatusEntity> statusHistory;
  final String? specialInstructions;
  final String? couponCode;
  final double? couponDiscount;
  final DateTime estimatedDeliveryTime;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImage,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.discount,
    required this.total,
    required this.status,
    required this.paymentMethod,
    this.paymentId,
    required this.isPaid,
    required this.deliveryAddress,
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.riderLocation,
    required this.statusHistory,
    this.specialInstructions,
    this.couponCode,
    this.couponDiscount,
    required this.estimatedDeliveryTime,
    this.deliveredAt,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        restaurantId,
        restaurantName,
        restaurantImage,
        items,
        subtotal,
        deliveryFee,
        tax,
        discount,
        total,
        status,
        paymentMethod,
        paymentId,
        isPaid,
        deliveryAddress,
        riderId,
        riderName,
        riderPhone,
        riderLocation,
        statusHistory,
        specialInstructions,
        couponCode,
        couponDiscount,
        estimatedDeliveryTime,
        deliveredAt,
        createdAt,
        updatedAt,
      ];
}

class OrderItemEntity extends Equatable {
  final String id;
  final String menuItemId;
  final String name;
  final String? image;
  final double price;
  final int quantity;
  final List<AddonEntity>? selectedAddons;
  final VariantEntity? selectedVariant;

  const OrderItemEntity({
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

class OrderStatusEntity extends Equatable {
  final String status;
  final DateTime timestamp;
  final String? note;
  final String? updatedBy;

  const OrderStatusEntity({
    required this.status,
    required this.timestamp,
    this.note,
    this.updatedBy,
  });

  @override
  List<Object?> get props => [status, timestamp, note, updatedBy];
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
