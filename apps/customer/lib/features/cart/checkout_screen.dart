import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedAddressId;
  String _payment = 'upi';
  final List<String> _instructions = [];
  bool _scheduleLater = false;
  bool _loading = false;

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider.notifier);
    final user = ref.read(authProvider).user;
    if (user == null) {
      _showSnack('Please login to place an order', isError: true);
      context.go('/login');
      return;
    }
    setState(() => _loading = true);
    try {
      final cartItems = ref.read(cartProvider);
      final payload = {
        'restaurantId': cart.restaurantId ?? '',
        'items': cartItems.map((i) => {
          'menuItemId': i.menuItemId,
          'name': i.name,
          'price': i.price,
          'quantity': i.quantity,
          'isVeg': i.isVeg,
        }).toList(),
        'subtotal': cart.subtotal,
        'deliveryFee': cart.deliveryFee,
        'tax': cart.tax,
        'platformFee': AppConstants.platformFee,
        'packagingCharge': AppConstants.packagingCharge,
        'discount': cart.discount,
        'tip': cart.tip,
        'total': cart.total,
        'paymentMethod': _payment,
        'specialInstructions': _instructions.join(', '),
        if (_selectedAddressId != null) 'deliveryAddressId': _selectedAddressId,
      };
      final order = await OrderApi().placeOrder(payload);
      cart.clear();
      if (mounted) context.go('/order/${order.id}');
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Failed to place order. Please try again.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : const Color(0xFF2ECC71),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider.notifier);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1C)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1C1C1C))),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE23744)),
                  SizedBox(height: 16),
                  Text('Placing your order...', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDeliveryAddressSection(user),
                const SizedBox(height: 16),
                _buildInstructionsSection(),
                const SizedBox(height: 16),
                _buildScheduleSection(),
                const SizedBox(height: 16),
                _buildPaymentSection(cart, user),
                const SizedBox(height: 16),
                _buildOrderSummary(cart),
                const SizedBox(height: 100),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE23744),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Place Order • ₹${cart.total.toInt()}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
    );
  }

  Widget _buildDeliveryAddressSection(user) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: Color(0xFFE23744), size: 18),
              SizedBox(width: 8),
              Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE23744).withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.home_rounded, color: Color(0xFFE23744), size: 16),
                      const SizedBox(width: 6),
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(user.phone ?? 'No phone saved',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ] else ...[
                  const Text('Login to add delivery address',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => context.push('/addresses'),
            icon: const Icon(Icons.add_location_alt_rounded, color: Color(0xFFE23744), size: 18),
            label: const Text('Change / Add Address', style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, color: Color(0xFFE23744), size: 18),
              SizedBox(width: 8),
              Text('Delivery Instructions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Leave at door', 'Ring the bell', 'Call on arrival', 'No cutlery', 'Extra napkins'].map((instr) {
              final selected = _instructions.contains(instr);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) _instructions.remove(instr);
                  else _instructions.add(instr);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFFEEEF) : const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? const Color(0xFFE23744) : const Color(0xFFE0E0E0)),
                  ),
                  child: Text(
                    instr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? const Color(0xFFE23744) : const Color(0xFF666666),
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

  Widget _buildScheduleSection() {
    return _Card(
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: Color(0xFFE23744), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule for Later', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('Pick a time slot for delivery', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: _scheduleLater,
            onChanged: (v) => setState(() => _scheduleLater = v),
            activeColor: const Color(0xFFE23744),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(CartNotifier cart, user) {
    final walletBal = user?.walletBalance ?? 0;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment_rounded, color: Color(0xFFE23744), size: 18),
              SizedBox(width: 8),
              Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          _paymentTile('upi', Icons.qr_code_scanner_rounded, 'UPI / Net Banking'),
          _paymentTile('card', Icons.credit_card_rounded, 'Credit / Debit Card'),
          _paymentTile('wallet', Icons.account_balance_wallet_rounded, 'CraveX Wallet  (₹${walletBal.toInt()})'),
          _paymentTile('cod', Icons.money_rounded, 'Cash on Delivery'),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartNotifier cart) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          _row('Item Total', cart.subtotal),
          _row('Delivery Fee', cart.deliveryFee),
          _row('Platform Fee', AppConstants.platformFee),
          _row('Packaging', AppConstants.packagingCharge),
          _row('GST & Taxes', cart.tax),
          if (cart.discount > 0) _row('Discount', -cart.discount, color: const Color(0xFF2ECC71)),
          if (cart.tip > 0) _row('Tip for Rider', cart.tip),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          _row('Total', cart.total, bold: true),
        ],
      ),
    );
  }

  Widget _paymentTile(String value, IconData icon, String label) {
    final selected = _payment == value;
    return GestureDetector(
      onTap: () => setState(() => _payment = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEEEF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFFE23744) : const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFFE23744) : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: selected ? const Color(0xFFE23744) : const Color(0xFF1C1C1C)))),
            if (selected) const Icon(Icons.check_circle_rounded, color: Color(0xFFE23744), size: 18),
          ],
        ),
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
            '${amount < 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}',
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

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: child,
    );
  }
}
