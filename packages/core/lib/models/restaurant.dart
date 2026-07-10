import 'package:equatable/equatable.dart';

class Restaurant extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> cuisines;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final int deliveryTime;
  final double deliveryFee;
  final int costForTwo;
  final bool isPureVeg;
  final bool isOpen;
  final String? coverImage;
  final String? fssaiLicense;
  final List<String> openingHours;
  final double distanceKm;
  final bool hasOffer;
  final String? offerText;

  const Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.cuisines,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.costForTwo,
    required this.isPureVeg,
    required this.isOpen,
    this.coverImage,
    this.fssaiLicense,
    this.openingHours = const [],
    this.distanceKm = 0,
    this.hasOffer = false,
    this.offerText,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        cuisines: List<String>.from(json['cuisines'] ?? json['cuisine'] ?? []),
        address: json['address'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        deliveryTime: json['deliveryTime'] as int? ?? 30,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 40,
        costForTwo: json['costForTwo'] as int? ?? 500,
        isPureVeg: json['isPureVeg'] as bool? ?? json['veg'] as bool? ?? false,
        isOpen: json['isOpen'] as bool? ?? true,
        coverImage: json['coverImage'] as String? ?? json['imageUrl'] as String?,
        fssaiLicense: json['fssaiLicense'] as String?,
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
        hasOffer: json['hasOffer'] as bool? ?? false,
        offerText: json['offerText'] as String?,
      );

  @override
  List<Object?> get props => [id, name, rating, isOpen];
}
