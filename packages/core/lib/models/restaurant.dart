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
        cuisines: List<String>.from(
          json['cuisine_types'] ?? json['cuisines'] ?? json['cuisine'] ?? [],
        ),
        address: [
          json['address_line1'] ?? '',
          json['city'] ?? '',
        ].where((s) => (s as String).isNotEmpty).join(', '),
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
        reviewCount: (json['total_reviews'] ?? json['reviewCount'] ?? 0) as int,
        deliveryTime: (json['average_delivery_time'] ?? json['deliveryTime'] ?? 30) as int,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 40,
        costForTwo: ((json['cost_for_two'] ?? json['costForTwo'] ?? 500) as num).toInt(),
        isPureVeg: json['is_pure_veg'] as bool? ?? json['isPureVeg'] as bool? ?? false,
        isOpen: json['is_available'] as bool? ?? json['isOpen'] as bool? ?? true,
        coverImage: json['cover_image_url'] as String? ??
            json['coverImage'] as String? ??
            json['imageUrl'] as String?,
        fssaiLicense: json['fssai_license'] as String? ?? json['fssaiLicense'] as String?,
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
        hasOffer: json['hasOffer'] as bool? ?? false,
        offerText: json['offerText'] as String?,
      );

  @override
  List<Object?> get props => [id, name, rating, isOpen];
}
