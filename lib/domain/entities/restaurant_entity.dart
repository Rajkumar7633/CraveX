import 'package:equatable/equatable.dart';

class RestaurantEntity extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String? logo;
  final String? coverImage;
  final List<String> images;
  final String cuisine;
  final List<String> cuisines;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final int deliveryTime;
  final double deliveryFee;
  final double minimumOrder;
  final bool isPureVeg;
  final bool isAvailable;
  final String? licenseNumber;
  final String? fssaiLicense;
  final List<String> openingHours;
  final String priceRange;
  final List<String> features;
  final List<OfferEntity>? offers;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RestaurantEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    this.logo,
    this.coverImage,
    required this.images,
    required this.cuisine,
    required this.cuisines,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minimumOrder,
    required this.isPureVeg,
    required this.isAvailable,
    this.licenseNumber,
    this.fssaiLicense,
    required this.openingHours,
    required this.priceRange,
    required this.features,
    this.offers,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        description,
        logo,
        coverImage,
        images,
        cuisine,
        cuisines,
        address,
        latitude,
        longitude,
        rating,
        reviewCount,
        deliveryTime,
        deliveryFee,
        minimumOrder,
        isPureVeg,
        isAvailable,
        licenseNumber,
        fssaiLicense,
        openingHours,
        priceRange,
        features,
        offers,
        createdAt,
        updatedAt,
      ];
}

class OfferEntity extends Equatable {
  final String id;
  final String restaurantId;
  final String title;
  final String description;
  final String code;
  final String discountType;
  final double discountValue;
  final double minOrderValue;
  final double maxDiscount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int usageLimit;
  final int usageCount;

  const OfferEntity({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.description,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    required this.maxDiscount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.usageLimit,
    required this.usageCount,
  });

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        title,
        description,
        code,
        discountType,
        discountValue,
        minOrderValue,
        maxDiscount,
        startDate,
        endDate,
        isActive,
        usageLimit,
        usageCount,
      ];
}
