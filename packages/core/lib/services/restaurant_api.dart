import 'package:dio/dio.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import 'api_client.dart';

class RestaurantApi {
  final _dio = ApiClient().restaurantDio;

  Future<List<Restaurant>> getRestaurants({
    double? lat,
    double? lng,
    String? cuisine,
    bool? isVeg,
    String? sortBy,
  }) async {
    final resp = await _dio.get('/restaurants', queryParameters: {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (cuisine != null) 'cuisine': cuisine,
      if (isVeg == true) 'isVeg': true,
      if (sortBy != null) 'sortBy': sortBy,
      'limit': 20,
    });
    final data = resp.data;
    List list;
    if (data is Map && data['restaurants'] != null) {
      list = data['restaurants'] as List;
    } else if (data is List) {
      list = data;
    } else {
      return [];
    }
    return list.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Restaurant> getRestaurantById(String id) async {
    final resp = await _dio.get('/restaurants/$id');
    return Restaurant.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Map<String, List<MenuItem>>> getMenu(String restaurantId) async {
    final resp = await _dio.get('/restaurants/$restaurantId/menu');
    final data = resp.data;

    List rawItems;
    if (data is List) {
      rawItems = data;
    } else if (data is Map && data['items'] != null) {
      rawItems = data['items'] as List;
    } else if (data is Map && data['categories'] != null) {
      // legacy grouped format
      final Map<String, List<MenuItem>> result = {};
      for (final cat in data['categories'] as List) {
        final catMap = cat as Map<String, dynamic>;
        final catName = catMap['name'] as String? ?? 'Menu';
        final items = (catMap['items'] as List? ?? [])
            .map((i) => MenuItem.fromJson(i as Map<String, dynamic>))
            .toList();
        result[catName] = items;
      }
      return result;
    } else {
      return {};
    }

    // Flat list — group by category name from embedded category object
    final Map<String, List<MenuItem>> result = {};
    for (final raw in rawItems) {
      final itemMap = raw as Map<String, dynamic>;
      final catMap = itemMap['category'] as Map<String, dynamic>?;
      final catName = catMap?['name'] as String? ?? 'Menu';
      final item = MenuItem.fromJson(itemMap);
      result.putIfAbsent(catName, () => []).add(item);
    }
    return result;
  }

  Future<List<Restaurant>> searchRestaurants(String query) async {
    final resp = await _dio.get('/restaurants/search', queryParameters: {'q': query});
    final data = resp.data;
    List list;
    if (data is Map && data['restaurants'] != null) {
      list = data['restaurants'] as List;
    } else if (data is List) {
      list = data;
    } else {
      return [];
    }
    return list.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  }
}
