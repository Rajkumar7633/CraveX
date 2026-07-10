import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zomato_clone/domain/entities/restaurant_entity.dart';

part 'restaurant_model.g.dart';

@JsonSerializable()
class RestaurantModel extends Equatable {
  final String id;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  final String name;
  final String description;
  final String? logo;
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  final List<String> images;
  final String cuisine;
  final List<String> cuisines;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  @JsonKey(name: 'review_count')
  final int reviewCount;
  @JsonKey(name: 'delivery_time')
  final int deliveryTime;
  @JsonKey(name: 'delivery_fee')
  final double deliveryFee;
  @JsonKey(name: 'minimum_order')
  final double minimumOrder;
  @JsonKey(name: 'is_pure_veg')
  final bool isPureVeg;
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @JsonKey(name: 'license_number')
  final String? licenseNumber;
  @JsonKey(name: 'fssai_license')
  final String? fssaiLicense;
  @JsonKey(name: 'opening_hours')
  final List<String> openingHours;
  @JsonKey(name: 'price_range')
  final String priceRange;
  final List<String> features;
  final List<OfferModel>? offers;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const RestaurantModel({
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

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      _$RestaurantModelFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantModelToJson(this);

  RestaurantEntity toEntity() {
    return RestaurantEntity(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      logo: logo,
      coverImage: coverImage,
      images: images,
      cuisine: cuisine,
      cuisines: cuisines,
      address: address,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      reviewCount: reviewCount,
      deliveryTime: deliveryTime,
      deliveryFee: deliveryFee,
      minimumOrder: minimumOrder,
      isPureVeg: isPureVeg,
      isAvailable: isAvailable,
      licenseNumber: licenseNumber,
      fssaiLicense: fssaiLicense,
      openingHours: openingHours,
      priceRange: priceRange,
      features: features,
      offers: offers?.map((e) => e.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory RestaurantModel.fromEntity(RestaurantEntity entity) {
    return RestaurantModel(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      description: entity.description,
      logo: entity.logo,
      coverImage: entity.coverImage,
      images: entity.images,
      cuisine: entity.cuisine,
      cuisines: entity.cuisines,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
      rating: entity.rating,
      reviewCount: entity.reviewCount,
      deliveryTime: entity.deliveryTime,
      deliveryFee: entity.deliveryFee,
      minimumOrder: entity.minimumOrder,
      isPureVeg: entity.isPureVeg,
      isAvailable: entity.isAvailable,
      licenseNumber: entity.licenseNumber,
      fssaiLicense: entity.fssaiLicense,
      openingHours: entity.openingHours,
      priceRange: entity.priceRange,
      features: entity.features,
      offers: entity.offers?.map((e) => OfferModel.fromEntity(e)).toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

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

@JsonSerializable()
class OfferModel extends Equatable {
  final String id;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  final String title;
  final String description;
  final String code;
  @JsonKey(name: 'discount_type')
  final String discountType;
  @JsonKey(name: 'discount_value')
  final double discountValue;
  @JsonKey(name: 'min_order_value')
  final double minOrderValue;
  @JsonKey(name: 'max_discount')
  final double maxDiscount;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'usage_limit')
  final int usageLimit;
  @JsonKey(name: 'usage_count')
  final int usageCount;

  const OfferModel({
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

  factory OfferModel.fromJson(Map<String, dynamic> json) =>
      _$OfferModelFromJson(json);

  Map<String, dynamic> toJson() => _$OfferModelToJson(this);

  OfferEntity toEntity() {
    return OfferEntity(
      id: id,
      restaurantId: restaurantId,
      title: title,
      description: description,
      code: code,
      discountType: discountType,
      discountValue: discountValue,
      minOrderValue: minOrderValue,
      maxDiscount: maxDiscount,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      usageLimit: usageLimit,
      usageCount: usageCount,
    );
  }

  factory OfferModel.fromEntity(OfferEntity entity) {
    return OfferModel(
      id: entity.id,
      restaurantId: entity.restaurantId,
      title: entity.title,
      description: entity.description,
      code: entity.code,
      discountType: entity.discountType,
      discountValue: entity.discountValue,
      minOrderValue: entity.minOrderValue,
      maxDiscount: entity.maxDiscount,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isActive: entity.isActive,
      usageLimit: entity.usageLimit,
      usageCount: entity.usageCount,
    );
  }

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
