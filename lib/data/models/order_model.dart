import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zomato_clone/domain/entities/order_entity.dart';

part 'order_model.g.dart';

@JsonSerializable()
class OrderModel extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  @JsonKey(name: 'restaurant_name')
  final String restaurantName;
  @JsonKey(name: 'restaurant_image')
  final String? restaurantImage;
  final List<OrderItemModel> items;
  final double subtotal;
  @JsonKey(name: 'delivery_fee')
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final String status;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'payment_id')
  final String? paymentId;
  @JsonKey(name: 'is_paid')
  final bool isPaid;
  @JsonKey(name: 'delivery_address')
  final AddressModel deliveryAddress;
  @JsonKey(name: 'rider_id')
  final String? riderId;
  @JsonKey(name: 'rider_name')
  final String? riderName;
  @JsonKey(name: 'rider_phone')
  final String? riderPhone;
  @JsonKey(name: 'rider_location')
  final String? riderLocation;
  @JsonKey(name: 'status_history')
  final List<OrderStatusModel> statusHistory;
  @JsonKey(name: 'special_instructions')
  final String? specialInstructions;
  @JsonKey(name: 'coupon_code')
  final String? couponCode;
  @JsonKey(name: 'coupon_discount')
  final double? couponDiscount;
  @JsonKey(name: 'estimated_delivery_time')
  final DateTime estimatedDeliveryTime;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const OrderModel({
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

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      userId: userId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantImage: restaurantImage,
      items: items.map((e) => e.toEntity()).toList(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      tax: tax,
      discount: discount,
      total: total,
      status: status,
      paymentMethod: paymentMethod,
      paymentId: paymentId,
      isPaid: isPaid,
      deliveryAddress: deliveryAddress.toEntity(),
      riderId: riderId,
      riderName: riderName,
      riderPhone: riderPhone,
      riderLocation: riderLocation,
      statusHistory: statusHistory.map((e) => e.toEntity()).toList(),
      specialInstructions: specialInstructions,
      couponCode: couponCode,
      couponDiscount: couponDiscount,
      estimatedDeliveryTime: estimatedDeliveryTime,
      deliveredAt: deliveredAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      userId: entity.userId,
      restaurantId: entity.restaurantId,
      restaurantName: entity.restaurantName,
      restaurantImage: entity.restaurantImage,
      items: entity.items.map((e) => OrderItemModel.fromEntity(e)).toList(),
      subtotal: entity.subtotal,
      deliveryFee: entity.deliveryFee,
      tax: entity.tax,
      discount: entity.discount,
      total: entity.total,
      status: entity.status,
      paymentMethod: entity.paymentMethod,
      paymentId: entity.paymentId,
      isPaid: entity.isPaid,
      deliveryAddress: AddressModel.fromEntity(entity.deliveryAddress),
      riderId: entity.riderId,
      riderName: entity.riderName,
      riderPhone: entity.riderPhone,
      riderLocation: entity.riderLocation,
      statusHistory: entity.statusHistory
          .map((e) => OrderStatusModel.fromEntity(e))
          .toList(),
      specialInstructions: entity.specialInstructions,
      couponCode: entity.couponCode,
      couponDiscount: entity.couponDiscount,
      estimatedDeliveryTime: entity.estimatedDeliveryTime,
      deliveredAt: entity.deliveredAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

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

@JsonSerializable()
class OrderItemModel extends Equatable {
  final String id;
  @JsonKey(name: 'menu_item_id')
  final String menuItemId;
  final String name;
  final String? image;
  final double price;
  final int quantity;
  @JsonKey(name: 'selected_addons')
  final List<AddonModel>? selectedAddons;
  @JsonKey(name: 'selected_variant')
  final VariantModel? selectedVariant;

  const OrderItemModel({
    required this.id,
    required this.menuItemId,
    required this.name,
    this.image,
    required this.price,
    required this.quantity,
    this.selectedAddons,
    this.selectedVariant,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);

  OrderItemEntity toEntity() {
    return OrderItemEntity(
      id: id,
      menuItemId: menuItemId,
      name: name,
      image: image,
      price: price,
      quantity: quantity,
      selectedAddons: selectedAddons?.map((e) => e.toEntity()).toList(),
      selectedVariant: selectedVariant?.toEntity(),
    );
  }

  factory OrderItemModel.fromEntity(OrderItemEntity entity) {
    return OrderItemModel(
      id: entity.id,
      menuItemId: entity.menuItemId,
      name: entity.name,
      image: entity.image,
      price: entity.price,
      quantity: entity.quantity,
      selectedAddons:
          entity.selectedAddons?.map((e) => AddonModel.fromEntity(e)).toList(),
      selectedVariant: entity.selectedVariant != null
          ? VariantModel.fromEntity(entity.selectedVariant!)
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, menuItemId, name, image, price, quantity, selectedAddons, selectedVariant];
}

@JsonSerializable()
class OrderStatusModel extends Equatable {
  final String status;
  final DateTime timestamp;
  final String? note;
  @JsonKey(name: 'updated_by')
  final String? updatedBy;

  const OrderStatusModel({
    required this.status,
    required this.timestamp,
    this.note,
    this.updatedBy,
  });

  factory OrderStatusModel.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderStatusModelToJson(this);

  OrderStatusEntity toEntity() {
    return OrderStatusEntity(
      status: status,
      timestamp: timestamp,
      note: note,
      updatedBy: updatedBy,
    );
  }

  factory OrderStatusModel.fromEntity(OrderStatusEntity entity) {
    return OrderStatusModel(
      status: entity.status,
      timestamp: entity.timestamp,
      note: entity.note,
      updatedBy: entity.updatedBy,
    );
  }

  @override
  List<Object?> get props => [status, timestamp, note, updatedBy];
}

@JsonSerializable()
class AddressModel extends Equatable {
  final String id;
  final String label;
  @JsonKey(name: 'address_line1')
  final String addressLine1;
  @JsonKey(name: 'address_line2')
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final String? landmark;

  const AddressModel({
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

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);

  AddressEntity toEntity() {
    return AddressEntity(
      id: id,
      label: label,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
      landmark: landmark,
    );
  }

  factory AddressModel.fromEntity(AddressEntity entity) {
    return AddressModel(
      id: entity.id,
      label: entity.label,
      addressLine1: entity.addressLine1,
      addressLine2: entity.addressLine2,
      city: entity.city,
      state: entity.state,
      pincode: entity.pincode,
      latitude: entity.latitude,
      longitude: entity.longitude,
      landmark: entity.landmark,
    );
  }

  @override
  List<Object?> get props =>
      [id, label, addressLine1, addressLine2, city, state, pincode, latitude, longitude, landmark];
}

@JsonSerializable()
class AddonModel extends Equatable {
  final String id;
  final String name;
  final double price;

  const AddonModel({
    required this.id,
    required this.name,
    required this.price,
  });

  factory AddonModel.fromJson(Map<String, dynamic> json) =>
      _$AddonModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddonModelToJson(this);

  AddonEntity toEntity() {
    return AddonEntity(
      id: id,
      name: name,
      price: price,
    );
  }

  factory AddonModel.fromEntity(AddonEntity entity) {
    return AddonModel(
      id: entity.id,
      name: entity.name,
      price: entity.price,
    );
  }

  @override
  List<Object?> get props => [id, name, price];
}

@JsonSerializable()
class VariantModel extends Equatable {
  final String id;
  final String name;
  final double price;

  const VariantModel({
    required this.id,
    required this.name,
    required this.price,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) =>
      _$VariantModelFromJson(json);

  Map<String, dynamic> toJson() => _$VariantModelToJson(this);

  VariantEntity toEntity() {
    return VariantEntity(
      id: id,
      name: name,
      price: price,
    );
  }

  factory VariantModel.fromEntity(VariantEntity entity) {
    return VariantModel(
      id: entity.id,
      name: entity.name,
      price: entity.price,
    );
  }

  @override
  List<Object?> get props => [id, name, price];
}
