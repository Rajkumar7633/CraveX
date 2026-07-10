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

  Order copyWith({String? status, String? riderId, String? riderName}) => Order(
        id: id,
        userId: userId,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        tax: tax,
        platformFee: platformFee,
        packagingCharge: packagingCharge,
        discount: discount,
        tip: tip,
        total: total,
        status: status ?? this.status,
        paymentMethod: paymentMethod,
        isPaid: isPaid,
        deliveryAddress: deliveryAddress,
        riderId: riderId ?? this.riderId,
        riderName: riderName ?? this.riderName,
        riderPhone: riderPhone,
        specialInstructions: specialInstructions,
        couponCode: couponCode,
        estimatedDeliveryTime: estimatedDeliveryTime,
        createdAt: createdAt,
        statusHistory: statusHistory,
      );

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
