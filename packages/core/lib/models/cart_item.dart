import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String menuItemId;
  final String restaurantId;
  final String name;
  final double price;
  final int quantity;
  final bool isVeg;
  final List<String> selectedAddOns;
  final String? variantName;

  const CartItem({
    required this.menuItemId,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.quantity,
    this.isVeg = true,
    this.selectedAddOns = const [],
    this.variantName,
  });

  double get lineTotal => price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        menuItemId: menuItemId,
        restaurantId: restaurantId,
        name: name,
        price: price,
        quantity: quantity ?? this.quantity,
        isVeg: isVeg,
        selectedAddOns: selectedAddOns,
        variantName: variantName,
      );

  @override
  List<Object?> get props => [menuItemId, quantity, name];
}
