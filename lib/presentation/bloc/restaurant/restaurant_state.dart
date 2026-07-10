import 'package:equatable/equatable.dart';
import 'package:zomato_clone/domain/entities/menu_item_entity.dart';
import 'package:zomato_clone/domain/entities/restaurant_entity.dart';

abstract class RestaurantState extends Equatable {
  const RestaurantState();

  @override
  List<Object?> get props => [];
}

class RestaurantInitial extends RestaurantState {
  const RestaurantInitial();
}

class RestaurantLoading extends RestaurantState {
  const RestaurantLoading();
}

class RestaurantLoaded extends RestaurantState {
  final List<RestaurantEntity> restaurants;

  const RestaurantLoaded({required this.restaurants});

  @override
  List<Object?> get props => [restaurants];
}

class RestaurantDetailLoaded extends RestaurantState {
  final RestaurantEntity restaurant;

  const RestaurantDetailLoaded({required this.restaurant});

  @override
  List<Object?> get props => [restaurant];
}

class RestaurantMenuLoaded extends RestaurantState {
  final List<MenuItemEntity> menuItems;

  const RestaurantMenuLoaded({required this.menuItems});

  @override
  List<Object?> get props => [menuItems];
}

class RestaurantMenuItemLoaded extends RestaurantState {
  final MenuItemEntity menuItem;

  const RestaurantMenuItemLoaded({required this.menuItem});

  @override
  List<Object?> get props => [menuItem];
}

class RestaurantCategoriesLoaded extends RestaurantState {
  final List<String> categories;

  const RestaurantCategoriesLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

class RestaurantOffersLoaded extends RestaurantState {
  final List<OfferEntity> offers;

  const RestaurantOffersLoaded({required this.offers});

  @override
  List<Object?> get props => [offers];
}

class RestaurantFavoritesLoaded extends RestaurantState {
  final List<RestaurantEntity> favorites;

  const RestaurantFavoritesLoaded({required this.favorites});

  @override
  List<Object?> get props => [favorites];
}

class RestaurantFavoriteStatusLoaded extends RestaurantState {
  final bool isFavorite;

  const RestaurantFavoriteStatusLoaded({required this.isFavorite});

  @override
  List<Object?> get props => [isFavorite];
}

class RestaurantError extends RestaurantState {
  final String message;

  const RestaurantError({required this.message});

  @override
  List<Object?> get props => [message];
}
