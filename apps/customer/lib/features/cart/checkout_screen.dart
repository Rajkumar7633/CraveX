import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _addressId = MockData.addresses.first.id;
  String _payment = 'upi';
  String _instructions = '';
  bool _scheduleLater = false;
  bool _loading = false;

  Future<void> _placeOrder() async {
    setState(() => _loading = true);
    final order = await OrderService().placeOrder(
      paymentMethod: _payment,
      addressId: _addressId,
      instructions: _instructions.isEmpty ? null : _instructions,
    );
    setState(() => _loading = false);
    if (mounted) context.go('/order/${order.id}');
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartService();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...MockData.addresses.map((a) => RadioListTile<String>(
                      title: Text(a.label),
                      subtitle: Text(a.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
                      value: a.id,
                      groupValue: _addressId,
                      onChanged: (v) => setState(() => _addressId = v!),
                    )),
                TextButton.icon(
                  onPressed: () => context.push('/addresses'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Address'),
                ),
                const Divider(height: 32),
                const Text('Delivery Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Leave at door', 'Call on arrival', 'No cutlery'].map((i) {
                    return FilterChip(
                      label: Text(i),
                      selected: _instructions.contains(i),
                      onSelected: (s) => setState(() {
                        _instructions = s ? i : '';
                      }),
                    );
                  }).toList(),
                ),
                SwitchListTile(
                  title: const Text('Schedule for later'),
                  value: _scheduleLater,
                  onChanged: (v) => setState(() => _scheduleLater = v),
                ),
                const Divider(height: 32),
                const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                _paymentTile('upi', Icons.account_balance, 'UPI'),
                _paymentTile('card', Icons.credit_card, 'Credit/Debit Card'),
                _paymentTile('wallet', Icons.account_balance_wallet, 'Wallet (₹${MockData.demoUser.walletBalance.toInt()})'),
                _paymentTile('cod', Icons.money, 'Cash on Delivery'),
                const Divider(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _row('Subtotal', cart.subtotal),
                        _row('Delivery', cart.deliveryFee),
                        _row('Taxes & Fees', cart.tax + AppConstants.platformFee + AppConstants.packagingCharge),
                        if (cart.discount > 0) _row('Discount', -cart.discount),
                        const Divider(),
                        _row('To Pay', cart.total, bold: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _loading ? null : _placeOrder,
            child: Text('Place Order • ₹${cart.total.toInt()}'),
          ),
        ),
      ),
    );
  }

  Widget _paymentTile(String value, IconData icon, String label) {
    return RadioListTile<String>(
      title: Row(children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)]),
      value: value,
      groupValue: _payment,
      onChanged: (v) => setState(() => _payment = v!),
    );
  }

  Widget _row(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          Text('₹${amount.abs().toStringAsFixed(0)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}
