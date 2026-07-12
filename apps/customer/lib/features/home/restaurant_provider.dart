import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestaurantCache {
  static const String _cacheKey = 'restaurant_list_cache';
  static const String _timestampKey = 'restaurant_list_timestamp';
  
  static Future<void> saveCache(List<Restaurant> restaurants) async {
    final prefs = await SharedPreferences.getInstance();
    final json = restaurants.map((r) => r.toJson()).toList();
    await prefs.setString(_cacheKey, json.toString());
    await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  static Future<List<Restaurant>?> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_timestampKey);
    
    if (timestamp == null) return null;
    
    final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    final maxAge = AppConstants.restaurantListCacheDuration * 1000; // Convert to milliseconds
    
    if (cacheAge > maxAge) {
      await clearCache();
      return null;
    }
    
    final json = prefs.getString(_cacheKey);
    if (json == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_timestampKey);
  }
}

final restaurantProvider = StateNotifierProvider<RestaurantNotifier, RestaurantState>((ref) {
  return RestaurantNotifier(ref);
});

class RestaurantState {
  final List<Restaurant> restaurants;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final bool hasError;

  const RestaurantState({
    this.restaurants = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.hasError = false,
  });

  RestaurantState copyWith({
    List<Restaurant>? restaurants,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool? hasError,
  }) {
    return RestaurantState(
      restaurants: restaurants ?? this.restaurants,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      hasError: hasError ?? this.hasError,
    );
  }
}

class RestaurantNotifier extends StateNotifier<RestaurantState> {
  final Ref ref;
  final ApiClient _apiClient;

  RestaurantNotifier(this.ref)
      : _apiClient = ApiClient(),
        super(const RestaurantState()) {
    _loadRestaurants();
  }

  Future<void> _loadRestaurants({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      state = state.copyWith(isLoading: true);
    } else {
      state = state.copyWith(isRefreshing: true);
    }

    try {
      // Try to load from cache first
      if (!forceRefresh) {
        final cached = await RestaurantCache.loadCache();
        if (cached != null) {
          state = state.copyWith(
            restaurants: cached,
            isLoading: false,
          );
          // Silently refresh in background
          _fetchFromApi();
          return;
        }
      }

      await _fetchFromApi();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
        hasError: true,
      );
    }
  }

  Future<void> _fetchFromApi() async {
    try {
      final response = await _apiClient.restaurantDio.get('/restaurants/nearby');
      final List<dynamic> data = response.data['restaurants'] as List<dynamic>;
      final restaurants = data.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
      
      await RestaurantCache.saveCache(restaurants);
      
      state = state.copyWith(
        restaurants: restaurants,
        isLoading: false,
        isRefreshing: false,
        hasError: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
        hasError: true,
      );
    }
  }

  Future<void> refresh() async {
    await _loadRestaurants(forceRefresh: true);
  }

  Future<void> clearCacheAndReload() async {
    await RestaurantCache.clearCache();
    await _loadRestaurants(forceRefresh: true);
  }
}
