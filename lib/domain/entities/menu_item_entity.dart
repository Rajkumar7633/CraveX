import 'package:equatable/equatable.dart';

class MenuItemEntity extends Equatable {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final String? image;
  final double price;
  final double? discountedPrice;
  final String category;
  final List<String> tags;
  final bool isVegetarian;
  final bool isAvailable;
  final int preparationTime;
  final int spiceLevel;
  final List<AddonEntity>? addons;
  final List<VariantEntity>? variants;
  final double rating;
  final int reviewCount;
  final int orderCount;
  final bool isRecommended;
  final bool isBestseller;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MenuItemEntity({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    this.image,
    required this.price,
    this.discountedPrice,
    required this.category,
    required this.tags,
    required this.isVegetarian,
    required this.isAvailable,
    required this.preparationTime,
    required this.spiceLevel,
    this.addons,
    this.variants,
    required this.rating,
    required this.reviewCount,
    required this.orderCount,
    required this.isRecommended,
    required this.isBestseller,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        name,
        description,
        image,
        price,
        discountedPrice,
        category,
        tags,
        isVegetarian,
        isAvailable,
        preparationTime,
        spiceLevel,
        addons,
        variants,
        rating,
        reviewCount,
        orderCount,
        isRecommended,
        isBestseller,
        createdAt,
        updatedAt,
      ];
}

class AddonEntity extends Equatable {
  final String id;
  final String menuItemId;
  final String name;
  final double price;
  final bool isAvailable;

  const AddonEntity({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [id, menuItemId, name, price, isAvailable];
}

class VariantEntity extends Equatable {
  final String id;
  final String menuItemId;
  final String name;
  final double price;
  final bool isAvailable;

  const VariantEntity({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [id, menuItemId, name, price, isAvailable];
}
