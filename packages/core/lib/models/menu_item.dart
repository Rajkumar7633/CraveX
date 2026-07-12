import 'package:equatable/equatable.dart';

class MenuCategory extends Equatable {
  final String id;
  final String name;
  final String restaurantId;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.restaurantId,
  });

  @override
  List<Object?> get props => [id, name];
}

class MenuItem extends Equatable {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isVeg;
  final bool isAvailable;
  final List<String> addOns;
  final List<MenuVariant> variants;
  final bool isRecommended;
  final int spiceLevel;

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.isVeg,
    this.isAvailable = true,
    this.addOns = const [],
    this.variants = const [],
    this.isRecommended = false,
    this.spiceLevel = 0,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as String,
        categoryId: json['category_id'] as String? ??
            json['categoryId'] as String? ??
            '',
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        price: (json['price'] as num).toDouble(),
        imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
        isVeg: json['is_vegetarian'] as bool? ??
            json['veg'] as bool? ??
            json['isVeg'] as bool? ??
            true,
        isAvailable:
            json['is_available'] as bool? ?? json['isAvailable'] as bool? ?? true,
        addOns: List<String>.from(json['addOns'] ?? []),
        isRecommended: json['is_featured'] as bool? ??
            json['isRecommended'] as bool? ??
            false,
        spiceLevel: json['spiceLevel'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [id, name, price, isAvailable];
}

class MenuVariant extends Equatable {
  final String id;
  final String name;
  final double price;

  const MenuVariant({required this.id, required this.name, required this.price});

  @override
  List<Object?> get props => [id, name, price];
}
