import '../constants/app_constants.dart';
import '../models/cart_item.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];
  String? _restaurantId;
  String? _couponCode;
  double _tip = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get restaurantId => _restaurantId;
  String? get couponCode => _couponCode;
  double get tip => _tip;
  bool get isEmpty => _items.isEmpty;

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.lineTotal);

  double get tax => subtotal * AppConstants.taxRate;

  double get deliveryFee =>
      subtotal >= 199 ? 0 : AppConstants.defaultDeliveryFee;

  double get discount {
    if (_couponCode == 'FIRST50') return subtotal * 0.5 > 100 ? 100 : subtotal * 0.5;
    if (_couponCode == 'FLAT100') return 100;
    if (_couponCode == 'FREEDEL') return deliveryFee;
    return 0;
  }

  double get total => subtotal +
      deliveryFee +
      tax +
      AppConstants.platformFee +
      AppConstants.packagingCharge +
      _tip -
      discount;

  void addItem(CartItem item) {
    if (_restaurantId != null && _restaurantId != item.restaurantId) {
      throw StateError('Cannot add items from different restaurants');
    }
    _restaurantId = item.restaurantId;
    final existing = _items.indexWhere((i) => i.menuItemId == item.menuItemId);
    if (existing >= 0) {
      _items[existing] = _items[existing].copyWith(
        quantity: _items[existing].quantity + item.quantity,
      );
    } else {
      _items.add(item);
    }
  }

  void updateQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuItemId);
      return;
    }
    final idx = _items.indexWhere((i) => i.menuItemId == menuItemId);
    if (idx >= 0) _items[idx] = _items[idx].copyWith(quantity: quantity);
  }

  void removeItem(String menuItemId) {
    _items.removeWhere((i) => i.menuItemId == menuItemId);
    if (_items.isEmpty) _restaurantId = null;
  }

  void applyCoupon(String code) => _couponCode = code;
  void setTip(double amount) => _tip = amount;
  void clear() {
    _items.clear();
    _restaurantId = null;
    _couponCode = null;
    _tip = 0;
  }
}
