import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [id, email, role];
}

class PendingRestaurant extends Equatable {
  final String id;
  final String name;
  final String ownerName;
  final String city;
  final String status;
  final DateTime submittedAt;
  final String? rejectReason;

  const PendingRestaurant({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.city,
    required this.status,
    required this.submittedAt,
    this.rejectReason,
  });

  @override
  List<Object?> get props => [id, status];
}

class PendingRider extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final String status;
  final DateTime submittedAt;

  const PendingRider({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.status,
    required this.submittedAt,
  });

  @override
  List<Object?> get props => [id, status];
}

class SupportTicket extends Equatable {
  final String id;
  final String subject;
  final String customerName;
  final String priority;
  final String status;
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.customerName,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, status];
}

class Coupon extends Equatable {
  final String code;
  final String type;
  final double discount;
  final double maxDiscount;
  final bool isActive;
  final String scope;

  const Coupon({
    required this.code,
    required this.type,
    required this.discount,
    required this.maxDiscount,
    this.isActive = true,
    this.scope = 'global',
  });

  @override
  List<Object?> get props => [code];
}

class BannerItem extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  const BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.isActive = true,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [id];
}

class PayoutRecord extends Equatable {
  final String id;
  final String entityName;
  final String entityType;
  final double amount;
  final String status;
  final DateTime date;

  const PayoutRecord({
    required this.id,
    required this.entityName,
    required this.entityType,
    required this.amount,
    required this.status,
    required this.date,
  });

  @override
  List<Object?> get props => [id];
}
