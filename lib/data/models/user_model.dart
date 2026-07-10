import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zomato_clone/domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String userType;
  final bool isVerified;
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final AddressModel? defaultAddress;
  final List<AddressModel>? addresses;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      phone: phone,
      profileImage: profileImage,
      userType: userType,
      isVerified: isVerified,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      defaultAddress: defaultAddress?.toEntity(),
      addresses: addresses?.map((e) => e.toEntity()).toList(),
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      profileImage: entity.profileImage,
      userType: entity.userType,
      isVerified: entity.isVerified,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      defaultAddress: entity.defaultAddress != null
          ? AddressModel.fromEntity(entity.defaultAddress!)
          : null,
      addresses: entity.addresses
          ?.map((e) => AddressModel.fromEntity(e))
          .toList(),
    );
  }

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

@JsonSerializable()
class AddressModel extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
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
  @JsonKey(name: 'is_default')
  final bool isDefault;
  final String? landmark;

  const AddressModel({
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

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);

  AddressEntity toEntity() {
    return AddressEntity(
      id: id,
      userId: userId,
      label: label,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
      landmark: landmark,
    );
  }

  factory AddressModel.fromEntity(AddressEntity entity) {
    return AddressModel(
      id: entity.id,
      userId: entity.userId,
      label: entity.label,
      addressLine1: entity.addressLine1,
      addressLine2: entity.addressLine2,
      city: entity.city,
      state: entity.state,
      pincode: entity.pincode,
      latitude: entity.latitude,
      longitude: entity.longitude,
      isDefault: entity.isDefault,
      landmark: entity.landmark,
    );
  }

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
