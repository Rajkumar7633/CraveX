import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String userType;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final AddressEntity? defaultAddress;
  final List<AddressEntity>? addresses;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    required this.userType,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.defaultAddress,
    this.addresses,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        profileImage,
        userType,
        isVerified,
        isActive,
        createdAt,
        updatedAt,
        defaultAddress,
        addresses,
      ];
}

class AddressEntity extends Equatable {
  final String id;
  final String userId;
  final String label;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final String? landmark;

  const AddressEntity({
    required this.id,
    required this.userId,
    required this.label,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    this.landmark,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        label,
        addressLine1,
        addressLine2,
        city,
        state,
        pincode,
        latitude,
        longitude,
        isDefault,
        landmark,
      ];
}
