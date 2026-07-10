import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cart = CartService();
  final _couponController = TextEditingController();
  double _tip = 0;

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (_cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text('Your cart is empty'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Browse Restaurants')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          TextButton(
            onPressed: () {
              _cart.clear();
              _refresh();
            },
            child: const Text('Clear', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._cart.items.map((item) => Card(
                child: ListTile(
                  leading: VegIndicator(isVeg: item.isVeg),
                  title: Text(item.name),
                  subtitle: Text('₹${item.price.toInt()} each'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          _cart.updateQuantity(item.menuItemId, item.quantity - 1);
                          _refresh();
                        },
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          _cart.updateQuantity(item.menuItemId, item.quantity + 1);
                          _refresh();
                        },
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),
          _buildCouponSection(),
          const SizedBox(height: 16),
          _buildTipSection(),
          const SizedBox(height: 16),
          _buildBillSummary(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              _cart.setTip(_tip);
              context.push('/checkout');
            },
            child: Text('Proceed to Checkout • ₹${_cart.total.toInt()}'),
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Apply Coupon', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                decoration: const InputDecoration(hintText: 'Enter coupon code'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                _cart.applyCoupon(_couponController.text.toUpperCase());
                _refresh();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: MockData.coupons.map((c) => ActionChip(
                label: Text(c['code'] as String),
                onPressed: () {
                  _couponController.text = c['code'] as String;
                  _cart.applyCoupon(c['code'] as String);
                  _refresh();
                },
              )).toList(),
        ),
      ],
    );
  }

  Widget _buildTipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tip Delivery Partner', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [0, 20, 30, 50].map((amount) {
            final selected = _tip == amount.toDouble();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(amount == 0 ? 'No Tip' : '₹$amount'),
                selected: selected,
                onSelected: (_) {
                  setState(() => _tip = amount.toDouble());
                  _cart.setTip(_tip);
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBillSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Item Total', _cart.subtotal),
            _row('Delivery Fee', _cart.deliveryFee),
            _row('Platform Fee', AppConstants.platformFee),
            _row('Packaging', AppConstants.packagingCharge),
            _row('Taxes', _cart.tax),
            if (_cart.discount > 0) _row('Discount', -_cart.discount, color: Colors.green),
            if (_tip > 0) _row('Tip', _tip),
            const Divider(),
            _row('Total', _cart.total, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double amount, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          Text('₹${amount.abs().toStringAsFixed(0)}',
              style: TextStyle(fontWeight: bold ? FontWeight.bold : null, color: color)),
        ],
      ),
    );
  }
}
