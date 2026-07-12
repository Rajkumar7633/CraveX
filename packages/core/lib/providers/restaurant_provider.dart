import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../services/restaurant_api.dart';

final _api = RestaurantApi();

// Restaurant list provider
final restaurantListProvider = FutureProvider.family<List<Restaurant>, Map<String, dynamic>>(
  (ref, params) => _api.getRestaurants(
    lat: params['lat'] as double?,
    lng: params['lng'] as double?,
    cuisine: params['cuisine'] as String?,
    isVeg: params['isVeg'] as bool?,
  ),
);

// Simple provider for homepage (no filters)
final nearbyRestaurantsProvider = FutureProvider<List<Restaurant>>(
  (ref) => _api.getRestaurants(),
);

// Restaurant detail provider
final restaurantDetailProvider = FutureProvider.family<Restaurant, String>(
  (ref, id) => _api.getRestaurantById(id),
);

// Menu provider
final menuProvider = FutureProvider.family<Map<String, List<MenuItem>>, String>(
  (ref, restaurantId) => _api.getMenu(restaurantId),
);

// Search provider
final searchProvider = FutureProvider.family<List<Restaurant>, String>(
  (ref, query) => query.isEmpty ? Future.value([]) : _api.searchRestaurants(query),
);
