import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  double _tip = 0;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);

    if (cartItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.shopping_cart_outlined, size: 48, color: Color(0xFFD0D0D0)),
              ),
              const SizedBox(height: 20),
              const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Add items from a restaurant to get started', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE23744),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Browse Restaurants', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1C)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('${cartItems.length} item${cartItems.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(cartProvider.notifier).clear(),
            child: const Text('Clear', style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Items
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Column(
              children: [
                ...cartItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Veg/Non-veg indicator
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                border: Border.all(color: item.isVeg ? const Color(0xFF2ECC71) : const Color(0xFFE23744), width: 1.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: item.isVeg ? const Color(0xFF2ECC71) : const Color(0xFFE23744),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('₹${item.price.toInt()} each', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            // Quantity stepper
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE23744)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _StepperButton(
                                    icon: Icons.remove,
                                    onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.menuItemId, item.quantity - 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('${item.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFFE23744))),
                                  ),
                                  _StepperButton(
                                    icon: Icons.add,
                                    onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.menuItemId, item.quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('₹${item.lineTotal.toInt()}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                      ),
                      if (i < cartItems.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Coupon
          _buildCouponSection(cart),

          const SizedBox(height: 16),

          // Address
          _buildAddressSection(),

          const SizedBox(height: 16),

          // Tip
          _buildTipSection(),

          const SizedBox(height: 16),

          // Bill summary
          _buildBillSummary(cart),

          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: ElevatedButton(
          onPressed: () {
            cart.setTip(_tip);
            context.push('/checkout');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE23744),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(
            'Proceed to Checkout • ₹${cart.total.toInt()}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: Color(0xFFE23744), size: 18),
              SizedBox(width: 8),
              Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/address-selection'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_rounded, color: Color(0xFF1C1C1C), size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Home', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('123 Main Street, Bangalore', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection(CartNotifier cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_offer_rounded, color: Color(0xFFE23744), size: 18),
              SizedBox(width: 8),
              Text('Apply Coupon', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter coupon code',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  cart.applyCoupon(_couponController.text.toUpperCase());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coupon applied!'), backgroundColor: Color(0xFF2ECC71)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE23744),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: ['FIRST50', 'FLAT100', 'FREEDEL'].map((code) => ActionChip(
              label: Text(code, style: const TextStyle(fontSize: 12)),
              backgroundColor: const Color(0xFFFFEEEF),
              side: const BorderSide(color: Color(0xFFE23744)),
              onPressed: () {
                _couponController.text = code;
                cart.applyCoupon(code);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTipSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_rounded, color: Color(0xFFE23744), size: 18),
              SizedBox(width: 8),
              Text('Tip your Rider', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('100% goes to your delivery partner', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [0, 20, 30, 50].map((amount) {
              final selected = _tip == amount.toDouble();
              return GestureDetector(
                onTap: () => setState(() {
                  _tip = amount.toDouble();
                  ref.read(cartProvider.notifier).setTip(_tip);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFE23744) : const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? const Color(0xFFE23744) : const Color(0xFFE0E0E0)),
                  ),
                  child: Text(
                    amount == 0 ? 'No Tip' : '₹$amount',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF1C1C1C),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBillSummary(CartNotifier cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 14),
          _row('Item Total', cart.subtotal),
          _row('Delivery Fee', cart.deliveryFee),
          _row('Platform Fee', AppConstants.platformFee),
          _row('Packaging', AppConstants.packagingCharge),
          _row('GST & Taxes', cart.tax),
          if (cart.discount > 0) _row('Discount', -cart.discount, color: const Color(0xFF2ECC71)),
          if (_tip > 0) _row('Tip for Rider', _tip),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _row('Total Amount', cart.total, bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, double amount, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 15 : 13, color: Colors.grey[700])),
          Text(
            '₹${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 16 : 13,
              color: color ?? (bold ? const Color(0xFF1C1C1C) : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: const Color(0xFFE23744)),
      ),
    );
  }
}
