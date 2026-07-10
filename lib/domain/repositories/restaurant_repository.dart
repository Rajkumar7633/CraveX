import 'package:dartz/dartz.dart';
import 'package:zomato_clone/core/error/failures.dart';
import 'package:zomato_clone/domain/entities/restaurant_entity.dart';
import 'package:zomato_clone/domain/entities/menu_item_entity.dart';

abstract class RestaurantRepository {
  Future<Either<Failure, List<RestaurantEntity>>> getRestaurants({
    required double latitude,
    required double longitude,
    required double radius,
    String? cuisine,
    String? searchQuery,
    bool? isPureVeg,
    bool? isAvailable,
    String? sortBy,
    int? page,
    int? limit,
  });

  Future<Either<Failure, RestaurantEntity>> getRestaurantById({
    required String restaurantId,
  });

  Future<Either<Failure, List<RestaurantEntity>>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    required double radius,
  });

  Future<Either<Failure, List<RestaurantEntity>>> searchRestaurants({
    required String query,
    double? latitude,
    double? longitude,
  });

  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems({
    required String restaurantId,
    String? category,
    bool? isVegetarian,
    String? searchQuery,
  });

  Future<Either<Failure, MenuItemEntity>> getMenuItemById({
    required String menuItemId,
  });

  Future<Either<Failure, List<String>>> getCategories({
    required String restaurantId,
  });

  Future<Either<Failure, List<OfferEntity>>> getOffers({
    required String restaurantId,
  });

  Future<Either<Failure, bool>> addFavorite({
    required String restaurantId,
  });

  Future<Either<Failure, bool>> removeFavorite({
    required String restaurantId,
  });

  Future<Either<Failure, List<RestaurantEntity>>> getFavorites();

  Future<Either<Failure, bool>> isFavorite({
    required String restaurantId,
  });
}
