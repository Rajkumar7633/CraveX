import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';
import '../home/restaurant_provider.dart';

class MenuItemDetailScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final String itemId;

  const MenuItemDetailScreen({super.key, required this.restaurantId, required this.itemId});

  @override
  ConsumerState<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends ConsumerState<MenuItemDetailScreen> {
  int _quantity = 1;
  final _selectedAddOns = <String>{};
  String? _selectedVariant;
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  void _calculateTotal() {
    final item = MockData.menuItems(widget.restaurantId).firstWhere((i) => i.id == widget.itemId);
    double price = item.price;
    
    if (_selectedVariant != null && item.variants != null) {
      final variant = item.variants!.firstWhere((v) => v.name == _selectedVariant);
      price = variant.price;
    }
    
    if (item.addOnObjects != null) {
      for (final addOn in item.addOnObjects!) {
        if (_selectedAddOns.contains(addOn.name)) {
          price += addOn.price;
        }
      }
    }
    
    setState(() {
      _totalPrice = price * _quantity;
    });
  }

  void _addToCart() {
    final item = MockData.menuItems(widget.restaurantId).firstWhere((i) => i.id == widget.itemId);
    
    ref.read(cartProvider.notifier).addItem(CartItem(
      menuItemId: item.id,
      restaurantId: widget.restaurantId,
      name: item.name,
      price: _totalPrice / _quantity,
      quantity: _quantity,
      isVeg: item.isVeg,
      variantName: _selectedVariant,
      selectedAddOns: _selectedAddOns.toList(),
    ));
    
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('${item.name} added to cart'),
        ],
      ),
      backgroundColor: const Color(0xFF2ECC71),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final item = MockData.menuItems(widget.restaurantId).firstWhere((i) => i.id == widget.itemId);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(item.name),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${_totalPrice.toInt()}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                    ),
                    const Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add to Cart'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.restaurant, size: 64, color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              VegIndicator(isVeg: item.isVeg),
              const SizedBox(width: 8),
              Expanded(child: Text(item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              Text(
                '₹${item.price.toInt()}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.description, style: TextStyle(color: Colors.grey[600])),
          if (item.spiceLevel != null) ...[
            const SizedBox(height: 8),
            Text('Spice level: ${'🌶️' * item.spiceLevel!}'),
          ],
          
          // Variants
          if (item.variants != null && item.variants!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Variants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...item.variants!.map((variant) => RadioListTile<String>(
              title: Text(variant.name),
              subtitle: Text('₹${variant.price.toInt()}'),
              value: variant.name,
              groupValue: _selectedVariant,
              onChanged: (value) {
                setState(() {
                  _selectedVariant = value;
                  _calculateTotal();
                });
              },
              activeColor: AppTheme.primaryRed,
            )),
          ],
          
          // Add-ons
          if (item.addOnObjects != null && item.addOnObjects!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Add-ons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...item.addOnObjects!.map((addOn) => CheckboxListTile(
              title: Text(addOn.name),
              subtitle: Text('₹${addOn.price.toInt()}'),
              value: _selectedAddOns.contains(addOn.name),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedAddOns.add(addOn.name);
                  } else {
                    _selectedAddOns.remove(addOn.name);
                  }
                  _calculateTotal();
                });
              },
              activeColor: AppTheme.primaryRed,
              controlAffinity: ListTileControlAffinity.leading,
            )),
          ],
          
          // Quantity
          const SizedBox(height: 24),
          const Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _quantity > 1
                    ? () {
                        setState(() {
                          _quantity--;
                          _calculateTotal();
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
              ),
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _quantity++;
                    _calculateTotal();
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
