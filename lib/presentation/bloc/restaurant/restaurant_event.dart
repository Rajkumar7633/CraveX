import 'package:equatable/equatable.dart';

abstract class RestaurantEvent extends Equatable {
  const RestaurantEvent();

  @override
  List<Object?> get props => [];
}

class RestaurantLoadRequested extends RestaurantEvent {
  final double latitude;
  final double longitude;
  final double radius;
  final String? cuisine;
  final String? searchQuery;
  final bool? isPureVeg;
  final bool? isAvailable;
  final String? sortBy;
  final int? page;
  final int? limit;

  const RestaurantLoadRequested({
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.cuisine,
    this.searchQuery,
    this.isPureVeg,
    this.isAvailable,
    this.sortBy,
    this.page,
    this.limit,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        radius,
        cuisine,
        searchQuery,
        isPureVeg,
        isAvailable,
        sortBy,
        page,
        limit,
      ];
}

class RestaurantLoadByIdRequested extends RestaurantEvent {
  final String restaurantId;

  const RestaurantLoadByIdRequested({required this.restaurantId});

  @override
  List<Object?> get props => [restaurantId];
}

class RestaurantLoadNearbyRequested extends RestaurantEvent {
  final double latitude;
  final double longitude;
  final double radius;

  const RestaurantLoadNearbyRequested({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  @override
  List<Object?> get props => [latitude, longitude, radius];
}

class RestaurantSearchRequested extends RestaurantEvent {
  final String query;
  final double? latitude;
  final double? longitude;

  const RestaurantSearchRequested({
    required this.query,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [query, latitude, longitude];
}

class RestaurantMenuLoadRequested extends RestaurantEvent {
  final String restaurantId;
  final String? category;
  final bool? isVegetarian;
  final String? searchQuery;

  const RestaurantMenuLoadRequested({
    required this.restaurantId,
    this.category,
    this.isVegetarian,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [restaurantId, category, isVegetarian, searchQuery];
}

class RestaurantMenuItemLoadRequested extends RestaurantEvent {
  final String menuItemId;

  const RestaurantMenuItemLoadRequested({required this.menuItemId});

  @override
  List<Object?> get props => [menuItemId];
}

class RestaurantCategoriesLoadRequested extends RestaurantEvent {
  final String restaurantId;

  const RestaurantCategoriesLoadRequested({required this.restaurantId});

  @override
  List<Object?> get props => [restaurantId];
}

class RestaurantOffersLoadRequested extends RestaurantEvent {
  final String restaurantId;

  const RestaurantOffersLoadRequested({required this.restaurantId});

  @override
  List<Object?> get props => [restaurantId];
}

class RestaurantAddFavoriteRequested extends RestaurantEvent {
  final String restaurantId;

  const RestaurantAddFavoriteRequested({required this.restaurantId});

  @override
  List<Object?> get props => [restaurantId];
}

class RestaurantRemoveFavoriteRequested extends RestaurantEvent {
  final String restaurantId;

  const RestaurantRemoveFavoriteRequested({required this.restaurantId});

  @override
  List<Object?> get props => [restaurantId];
}

class RestaurantLoadFavoritesRequested extends RestaurantEvent {
  const RestaurantLoadFavoritesRequested();
}

class RestaurantCheckFavoriteRequested extends RestaurantEvent {
  final String restaurantId;

  const RestaurantCheckFavoriteRequested({required this.restaurantId});

  @override
  List<Object?> get props => [restaurantId];
}
