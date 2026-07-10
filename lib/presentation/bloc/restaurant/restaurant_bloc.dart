import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zomato_clone/core/error/failures.dart';
import 'package:zomato_clone/core/utils/logger.dart';
import 'package:zomato_clone/domain/entities/menu_item_entity.dart';
import 'package:zomato_clone/domain/entities/restaurant_entity.dart';
import 'package:zomato_clone/domain/repositories/restaurant_repository.dart';
import 'package:zomato_clone/presentation/bloc/restaurant/restaurant_event.dart';
import 'package:zomato_clone/presentation/bloc/restaurant/restaurant_state.dart';

class RestaurantBloc extends Bloc<RestaurantEvent, RestaurantState> {
  final RestaurantRepository restaurantRepository;

  RestaurantBloc({required this.restaurantRepository})
      : super(const RestaurantInitial()) {
    on<RestaurantLoadRequested>(_onLoadRestaurants);
    on<RestaurantLoadByIdRequested>(_onLoadRestaurantById);
    on<RestaurantLoadNearbyRequested>(_onLoadNearbyRestaurants);
    on<RestaurantSearchRequested>(_onSearchRestaurants);
    on<RestaurantMenuLoadRequested>(_onLoadMenu);
    on<RestaurantMenuItemLoadRequested>(_onLoadMenuItem);
    on<RestaurantCategoriesLoadRequested>(_onLoadCategories);
    on<RestaurantOffersLoadRequested>(_onLoadOffers);
    on<RestaurantAddFavoriteRequested>(_onAddFavorite);
    on<RestaurantRemoveFavoriteRequested>(_onRemoveFavorite);
    on<RestaurantLoadFavoritesRequested>(_onLoadFavorites);
    on<RestaurantCheckFavoriteRequested>(_onCheckFavorite);
  }

  Future<void> _onLoadRestaurants(
    RestaurantLoadRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.getRestaurants(
      latitude: event.latitude,
      longitude: event.longitude,
      radius: event.radius,
      cuisine: event.cuisine,
      searchQuery: event.searchQuery,
      isPureVeg: event.isPureVeg,
      isAvailable: event.isAvailable,
      sortBy: event.sortBy,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load restaurants failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (restaurants) {
        AppLogger.info('Loaded ${restaurants.length} restaurants');
        emit(RestaurantLoaded(restaurants: restaurants));
      },
    );
  }

  Future<void> _onLoadRestaurantById(
    RestaurantLoadByIdRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.getRestaurantById(
      restaurantId: event.restaurantId,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load restaurant failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (restaurant) {
        AppLogger.info('Loaded restaurant: ${restaurant.name}');
        emit(RestaurantDetailLoaded(restaurant: restaurant));
      },
    );
  }

  Future<void> _onLoadNearbyRestaurants(
    RestaurantLoadNearbyRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.getNearbyRestaurants(
      latitude: event.latitude,
      longitude: event.longitude,
      radius: event.radius,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load nearby restaurants failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (restaurants) {
        AppLogger.info('Loaded ${restaurants.length} nearby restaurants');
        emit(RestaurantLoaded(restaurants: restaurants));
      },
    );
  }

  Future<void> _onSearchRestaurants(
    RestaurantSearchRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.searchRestaurants(
      query: event.query,
      latitude: event.latitude,
      longitude: event.longitude,
    );

    result.fold(
      (failure) {
        AppLogger.error('Search restaurants failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (restaurants) {
        AppLogger.info('Found ${restaurants.length} restaurants for "${event.query}"');
        emit(RestaurantLoaded(restaurants: restaurants));
      },
    );
  }

  Future<void> _onLoadMenu(
    RestaurantMenuLoadRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.getMenuItems(
      restaurantId: event.restaurantId,
      category: event.category,
      isVegetarian: event.isVegetarian,
      searchQuery: event.searchQuery,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load menu failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (menuItems) {
        AppLogger.info('Loaded ${menuItems.length} menu items');
        emit(RestaurantMenuLoaded(menuItems: menuItems));
      },
    );
  }

  Future<void> _onLoadMenuItem(
    RestaurantMenuItemLoadRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.getMenuItemById(
      menuItemId: event.menuItemId,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load menu item failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (menuItem) {
        AppLogger.info('Loaded menu item: ${menuItem.name}');
        emit(RestaurantMenuItemLoaded(menuItem: menuItem));
      },
    );
  }

  Future<void> _onLoadCategories(
    RestaurantCategoriesLoadRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.getCategories(
      restaurantId: event.restaurantId,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load categories failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (categories) {
        AppLogger.info('Loaded ${categories.length} categories');
        emit(RestaurantCategoriesLoaded(categories: categories));
      },
    );
  }

  Future<void> _onLoadOffers(
    RestaurantOffersLoadRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.getOffers(
      restaurantId: event.restaurantId,
    );

    result.fold(
      (failure) {
        AppLogger.error('Load offers failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (offers) {
        AppLogger.info('Loaded ${offers.length} offers');
        emit(RestaurantOffersLoaded(offers: offers));
      },
    );
  }

  Future<void> _onAddFavorite(
    RestaurantAddFavoriteRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.addFavorite(
      restaurantId: event.restaurantId,
    );

    result.fold(
      (failure) {
        AppLogger.error('Add favorite failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (success) {
        AppLogger.info('Added restaurant to favorites');
        emit(const RestaurantFavoriteStatusLoaded(isFavorite: true));
      },
    );
  }

  Future<void> _onRemoveFavorite(
    RestaurantRemoveFavoriteRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.removeFavorite(
      restaurantId: event.restaurantId,
    );

    result.fold(
      (failure) {
        AppLogger.error('Remove favorite failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (success) {
        AppLogger.info('Removed restaurant from favorites');
        emit(const RestaurantFavoriteStatusLoaded(isFavorite: false));
      },
    );
  }

  Future<void> _onLoadFavorites(
    RestaurantLoadFavoritesRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.getFavorites();

    result.fold(
      (failure) {
        AppLogger.error('Load favorites failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (favorites) {
        AppLogger.info('Loaded ${favorites.length} favorite restaurants');
        emit(RestaurantFavoritesLoaded(favorites: favorites));
      },
    );
  }

  Future<void> _onCheckFavorite(
    RestaurantCheckFavoriteRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    final result = await restaurantRepository.isFavorite(
      restaurantId: event.restaurantId,
    );

    result.fold(
      (failure) {
        AppLogger.error('Check favorite failed: ${failure.message}');
        emit(RestaurantError(message: failure.message));
      },
      (isFavorite) {
        AppLogger.info('Favorite status: $isFavorite');
        emit(RestaurantFavoriteStatusLoaded(isFavorite: isFavorite));
      },
    );
  }
}
