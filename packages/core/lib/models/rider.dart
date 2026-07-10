import 'package:equatable/equatable.dart';

class Rider extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? profilePhoto;
  final String vehicleType;
  final bool isOnline;
  final bool isVerified;
  final double rating;
  final int totalDeliveries;
  final double todayEarnings;
  final double latitude;
  final double longitude;

  const Rider({
    required this.id,
    required this.name,
    required this.phone,
    this.profilePhoto,
    required this.vehicleType,
    this.isOnline = false,
    this.isVerified = false,
    this.rating = 4.5,
    this.totalDeliveries = 0,
    this.todayEarnings = 0,
    this.latitude = 0,
    this.longitude = 0,
  });

  Rider copyWith({
    bool? isOnline,
    double? latitude,
    double? longitude,
    double? todayEarnings,
  }) =>
      Rider(
        id: id,
        name: name,
        phone: phone,
        profilePhoto: profilePhoto,
        vehicleType: vehicleType,
        isOnline: isOnline ?? this.isOnline,
        isVerified: isVerified,
        rating: rating,
        totalDeliveries: totalDeliveries,
        todayEarnings: todayEarnings ?? this.todayEarnings,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );

  @override
  List<Object?> get props => [id, name, isOnline];
}

class DeliveryRequest extends Equatable {
  final String orderId;
  final String restaurantName;
  final String restaurantAddress;
  final String customerAddress;
  final double earnings;
  final double distanceKm;
  final int expiresInSeconds;

  const DeliveryRequest({
    required this.orderId,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.customerAddress,
    required this.earnings,
    required this.distanceKm,
    this.expiresInSeconds = 15,
  });

  @override
  List<Object?> get props => [orderId];
}
