import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zomato_clone/core/router/app_router.dart';
import 'package:zomato_clone/core/services/payment_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _selectedAddress = 0;
  String _selectedPaymentMethod = 'cash';
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();
  late PaymentService _paymentService;
  bool _isProcessingPayment = false;

  final List<Address> _addresses = [
    Address(
      label: 'Home',
      address: '123 Main Street, Apt 4B',
      landmark: 'Near Central Park',
    ),
    Address(
      label: 'Office',
      address: '456 Business Ave, Suite 100',
      landmark: 'Downtown',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _paymentService.setCallbacks(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeliveryAddressSection(),
            const SizedBox(height: 24),
            _buildPaymentMethodSection(),
            const SizedBox(height: 24),
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _buildSpecialInstructions(),
            const SizedBox(height: 24),
            _buildBillDetails(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildDeliveryAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showAddAddressDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_addresses.length, (index) {
              return RadioListTile<int>(
                value: index,
                groupValue: _selectedAddress,
                onChanged: (value) {
                  setState(() {
                    _selectedAddress = value!;
                  });
                },
                title: Text(_addresses[index].label),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_addresses[index].address),
                    if (_addresses[index].landmark != null)
                      Text(
                        _addresses[index].landmark!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              value: 'cash',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when your order arrives'),
              secondary: const Icon(Icons.money),
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              value: 'card',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              title: const Text('Credit/Debit Card'),
              subtitle: const Text('Visa, Mastercard, Amex'),
              secondary: const Icon(Icons.credit_card),
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              value: 'upi',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              title: const Text('UPI'),
              subtitle: const Text('Google Pay, PhonePe, Paytm'),
              secondary: const Icon(Icons.payment),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOrderItem('Margherita Pizza', 2, 12.99),
            _buildOrderItem('Caesar Salad', 1, 8.99),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(String name, int quantity, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text('$name x$quantity'),
          ),
          Text('\$${(price * quantity).toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Special Instructions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special requests for your order?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillDetails() {
    final subtotal = 34.97;
    final deliveryFee = 2.99;
    final tax = subtotal * 0.08;
    final total = subtotal + deliveryFee + tax;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bill Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildBillRow('Item Total', '\$${subtotal.toStringAsFixed(2)}'),
            _buildBillRow('Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
            _buildBillRow('Tax (8%)', '\$${tax.toStringAsFixed(2)}'),
            const Divider(),
            _buildBillRow(
              'To Pay',
              '\$${total.toStringAsFixed(2)}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${(34.97 + 2.99 + 34.97 * 0.08).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _placeOrder();
                },
                child: const Text('Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Address'),
        content: TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_addressController.text.isNotEmpty) {
                setState(() {
                  _addresses.add(
                    Address(
                      label: 'New Address',
                      address: _addressController.text,
                    ),
                  );
                });
                _addressController.clear();
                context.pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _placeOrder() {
    if (_selectedPaymentMethod != 'cash') {
      _initiatePayment();
    } else {
      _processOrder();
    }
  }

  void _initiatePayment() {
    final total = 34.97 + 2.99 + 34.97 * 0.08;
    setState(() {
      _isProcessingPayment = true;
    });

    _paymentService.openPayment(
      key: PaymentConfig.razorpayKey,
      amount: total,
      orderId: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Zomato Clone',
      description: 'Food Delivery Order',
      contact: '1234567890',
      email: 'user@example.com',
      prefillAddress: _addresses[_selectedAddress].address,
      notes: {
        'order_type': 'food_delivery',
        'restaurant': 'Italian Kitchen',
      },
      themeColor: '#E23744',
    );
  }

  void _handlePaymentSuccess(String paymentId) {
    setState(() {
      _isProcessingPayment = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment successful! ID: $paymentId'),
        backgroundColor: Colors.green,
      ),
    );
    _processOrder();
  }

  void _handlePaymentError(String error) {
    setState(() {
      _isProcessingPayment = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('External wallet selected')),
    );
  }

  void _processOrder() {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Simulate order placement
    Future.delayed(const Duration(seconds: 2), () {
      context.pop(); // Close loading dialog
      context.push('${AppRouter.orderTracking}/123');
    });
  }
}

class Address {
  final String label;
  final String address;
  final String? landmark;

  Address({
    required this.label,
    required this.address,
    this.landmark,
  });
}
