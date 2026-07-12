import 'package:equatable/equatable.dart';
import 'address.dart';

class Order extends Equatable {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final List<OrderLineItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double platformFee;
  final double packagingCharge;
  final double discount;
  final double tip;
  final double total;
  final String status;
  final String paymentMethod;
  final bool isPaid;
  final Address deliveryAddress;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final String? specialInstructions;
  final String? couponCode;
  final DateTime estimatedDeliveryTime;
  final DateTime createdAt;
  final List<OrderStatusStep> statusHistory;

  const Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    this.platformFee = 5,
    this.packagingCharge = 10,
    this.discount = 0,
    this.tip = 0,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
    required this.deliveryAddress,
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.specialInstructions,
    this.couponCode,
    required this.estimatedDeliveryTime,
    required this.createdAt,
    this.statusHistory = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    Address parseAddress(dynamic a) {
      if (a == null) return const Address(id: '', label: '', addressLine1: '', city: '', state: '', pincode: '', latitude: 0, longitude: 0);
      final m = a as Map<String, dynamic>;
      return Address(
        id: m['id'] as String? ?? '',
        label: m['label'] as String? ?? 'Home',
        addressLine1: m['addressLine1'] as String? ?? m['address'] as String? ?? '',
        city: m['city'] as String? ?? '',
        state: m['state'] as String? ?? '',
        pincode: m['pincode'] as String? ?? '',
        latitude: (m['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (m['longitude'] as num?)?.toDouble() ?? 0,
      );
    }

    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      restaurantId: json['restaurantId'] as String? ?? '',
      restaurantName: json['restaurantName'] as String? ?? 'Restaurant',
      items: (json['items'] as List? ?? []).map((i) => OrderLineItem.fromJson(i as Map<String, dynamic>)).toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 5,
      packagingCharge: (json['packagingCharge'] as num?)?.toDouble() ?? 10,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      tip: (json['tip'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'placed',
      paymentMethod: json['paymentMethod'] as String? ?? 'cod',
      isPaid: json['isPaid'] as bool? ?? false,
      deliveryAddress: parseAddress(json['deliveryAddress']),
      riderId: json['riderId'] as String?,
      riderName: json['riderName'] as String?,
      riderPhone: json['riderPhone'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
      couponCode: json['couponCode'] as String?,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.tryParse(json['estimatedDeliveryTime'] as String) ?? DateTime.now().add(const Duration(minutes: 30))
          : DateTime.now().add(const Duration(minutes: 30)),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Order copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    String? restaurantName,
    List<OrderLineItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? platformFee,
    double? packagingCharge,
    double? discount,
    double? tip,
    double? total,
    String? status,
    String? paymentMethod,
    bool? isPaid,
    Address? deliveryAddress,
    String? riderId,
    String? riderName,
    String? riderPhone,
    String? specialInstructions,
    String? couponCode,
    DateTime? estimatedDeliveryTime,
    DateTime? createdAt,
    List<OrderStatusStep>? statusHistory,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      platformFee: platformFee ?? this.platformFee,
      packagingCharge: packagingCharge ?? this.packagingCharge,
      discount: discount ?? this.discount,
      tip: tip ?? this.tip,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      couponCode: couponCode ?? this.couponCode,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      createdAt: createdAt ?? this.createdAt,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  @override
  List<Object?> get props => [id, status, total];
}


class OrderLineItem extends Equatable {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final bool isVeg;
  final List<String> addOns;

  const OrderLineItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.isVeg = true,
    this.addOns = const [],
  });

  double get lineTotal => price * quantity;

  factory OrderLineItem.fromJson(Map<String, dynamic> json) => OrderLineItem(
        menuItemId: json['menuItemId'] as String? ?? json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        quantity: json['quantity'] as int? ?? 1,
        isVeg: json['isVeg'] as bool? ?? json['veg'] as bool? ?? true,
        addOns: List<String>.from(json['addOns'] ?? []),
      );

  @override
  List<Object?> get props => [menuItemId, name, quantity];
}

class OrderStatusStep extends Equatable {
  final String status;
  final DateTime timestamp;
  final String? note;

  const OrderStatusStep({
    required this.status,
    required this.timestamp,
    this.note,
  });

  @override
  List<Object?> get props => [status, timestamp];
}
