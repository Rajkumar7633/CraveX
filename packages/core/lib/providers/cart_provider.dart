import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/cart_item.dart';

// Cart state - persisted to SharedPreferences
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _loadFromPrefs();
  }

  String? _restaurantId;
  String? _couponCode;
  double _tip = 0;

  String? get restaurantId => _restaurantId;
  String? get couponCode => _couponCode;
  double get tip => _tip;

  double get subtotal => state.fold(0, (sum, item) => sum + item.lineTotal);
  double get tax => subtotal * AppConstants.taxRate;
  double get deliveryFee => subtotal >= 199 ? 0 : AppConstants.defaultDeliveryFee;
  double get discount {
    if (_couponCode == 'FIRST50') return subtotal * 0.5 > 100 ? 100 : subtotal * 0.5;
    if (_couponCode == 'FLAT100') return 100;
    if (_couponCode == 'FREEDEL') return deliveryFee;
    return 0;
  }
  double get total =>
      subtotal + deliveryFee + tax + AppConstants.platformFee + AppConstants.packagingCharge + _tip - discount;

  void addItem(CartItem item) {
    if (_restaurantId != null && _restaurantId != item.restaurantId) {
      // Clear cart when switching restaurants
      state = [];
      _restaurantId = null;
    }
    _restaurantId = item.restaurantId;
    final existing = state.indexWhere((i) => i.menuItemId == item.menuItemId);
    if (existing >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existing)
            state[i].copyWith(quantity: state[i].quantity + item.quantity)
          else
            state[i]
      ];
    } else {
      state = [...state, item];
    }
    _saveToPrefs();
  }

  void updateQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuItemId);
      return;
    }
    state = [
      for (final item in state)
        if (item.menuItemId == menuItemId) item.copyWith(quantity: quantity) else item
    ];
    _saveToPrefs();
  }

  void removeItem(String menuItemId) {
    state = state.where((i) => i.menuItemId != menuItemId).toList();
    if (state.isEmpty) _restaurantId = null;
    _saveToPrefs();
  }

  void applyCoupon(String code) {
    _couponCode = code;
    _saveToPrefs();
  }

  void removeCoupon() {
    _couponCode = null;
    _saveToPrefs();
  }

  void setTip(double amount) {
    _tip = amount;
  }

  void clear() {
    state = [];
    _restaurantId = null;
    _couponCode = null;
    _tip = 0;
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'restaurantId': _restaurantId,
      'couponCode': _couponCode,
      'tip': _tip,
      'items': state.map((i) => {
        'menuItemId': i.menuItemId,
        'restaurantId': i.restaurantId,
        'name': i.name,
        'price': i.price,
        'quantity': i.quantity,
        'isVeg': i.isVeg,
      }).toList(),
    };
    await prefs.setString('cart_data', jsonEncode(data));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cart_data');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _restaurantId = data['restaurantId'] as String?;
      _couponCode = data['couponCode'] as String?;
      _tip = (data['tip'] as num?)?.toDouble() ?? 0;
      final items = (data['items'] as List? ?? []).map((i) {
        final m = i as Map<String, dynamic>;
        return CartItem(
          menuItemId: m['menuItemId'] as String,
          restaurantId: m['restaurantId'] as String,
          name: m['name'] as String,
          price: (m['price'] as num).toDouble(),
          quantity: m['quantity'] as int,
          isVeg: m['isVeg'] as bool? ?? true,
        );
      }).toList();
      state = items;
    } catch (_) {}
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);
