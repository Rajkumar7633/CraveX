import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class MenuItemDetailScreen extends StatefulWidget {
  final String restaurantId;
  final String itemId;

  const MenuItemDetailScreen({super.key, required this.restaurantId, required this.itemId});

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  int _quantity = 1;
  final _selectedAddOns = <String>[];

  MenuItem get _item => MockData.menuItems(widget.restaurantId).firstWhere((i) => i.id == widget.itemId);

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Icon(Icons.restaurant, size: 64, color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              VegIndicator(isVeg: item.isVeg),
              const SizedBox(width: 8),
              Expanded(child: Text(item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              Text('₹${item.price.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.description, style: TextStyle(color: Colors.grey[600])),
          if (item.spiceLevel != null) ...[
            const SizedBox(height: 8),
            Text('Spice level: ${'🌶️' * item.spiceLevel!}'),
          ],
          if (item.addOns.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Add-ons', style: TextStyle(fontWeight: FontWeight.bold)),
            ...item.addOns.map((a) => CheckboxListTile(
                  title: Text(a),
                  value: _selectedAddOns.contains(a),
                  onChanged: (v) => setState(() => v! ? _selectedAddOns.add(a) : _selectedAddOns.remove(a)),
                  controlAffinity: ListTileControlAffinity.leading,
                )),
          ],
          const SizedBox(height: 16),
          const Text('Frequently ordered together', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, i) {
                final related = MockData.menuItems(widget.restaurantId)[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Chip(label: Text('${related.name} ₹${related.price.toInt()}')),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryRed), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove), onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null),
                    Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _quantity++)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    CartService().addItem(CartItem(
                      menuItemId: item.id,
                      restaurantId: widget.restaurantId,
                      name: item.name,
                      price: item.price,
                      quantity: _quantity,
                      isVeg: item.isVeg,
                      selectedAddOns: _selectedAddOns,
                    ));
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} added to cart')));
                  },
                  child: Text('Add — ₹${(item.price * _quantity).toInt()}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
