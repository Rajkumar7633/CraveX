import 'package:equatable/equatable.dart';

class RiderEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? drivingLicense;
  final bool isVerified;
  final bool isOnline;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final int totalDeliveries;
  final double totalEarnings;
  final double currentBalance;
  final String? currentOrderId;
  final LocationEntity? currentLocation;
  final List<String> documents;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RiderEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.vehicleType,
    this.vehicleNumber,
    this.drivingLicense,
    required this.isVerified,
    required this.isOnline,
    required this.isAvailable,
    required this.rating,
    required this.reviewCount,
    required this.totalDeliveries,
    required this.totalEarnings,
    required this.currentBalance,
    this.currentOrderId,
    this.currentLocation,
    required this.documents,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        email,
        phone,
        profileImage,
        vehicleType,
        vehicleNumber,
        drivingLicense,
        isVerified,
        isOnline,
        isAvailable,
        rating,
        reviewCount,
        totalDeliveries,
        totalEarnings,
        currentBalance,
        currentOrderId,
        currentLocation,
        documents,
        createdAt,
        updatedAt,
      ];
}

class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, address, timestamp];
}

class EarningEntity extends Equatable {
  final String id;
  final String riderId;
  final String orderId;
  final double amount;
  final double distance;
  final double duration;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double tip;
  final double commission;
  final double netEarning;
  final DateTime earnedAt;
  final String status;

  const EarningEntity({
    required this.id,
    required this.riderId,
    required this.orderId,
    required this.amount,
    required this.distance,
    required this.duration,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.tip,
    required this.commission,
    required this.netEarning,
    required this.earnedAt,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        riderId,
        orderId,
        amount,
        distance,
        duration,
        baseFare,
        distanceFare,
        timeFare,
        tip,
        commission,
        netEarning,
        earnedAt,
        status,
      ];
}
