import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _methods = [
    {'type': 'UPI', 'detail': 'rahul@upi', 'icon': Icons.account_balance},
    {'type': 'Card', 'detail': '**** **** **** 4242', 'icon': Icons.credit_card},
    {'type': 'Wallet', 'detail': 'Zomato Money — ₹250', 'icon': Icons.account_balance_wallet},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppTheme.primaryRed,
        icon: const Icon(Icons.add),
        label: const Text('Add Method'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _methods.length,
        itemBuilder: (_, i) {
          final m = _methods[i];
          return Card(
            child: ListTile(
              leading: Icon(m['icon'] as IconData, color: AppTheme.primaryRed),
              title: Text(m['type'] as String),
              subtitle: Text(m['detail'] as String),
              trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _methods.removeAt(i))),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.account_balance), title: const Text('UPI'), onTap: () { Navigator.pop(context); setState(() => _methods.add({'type': 'UPI', 'detail': 'new@upi', 'icon': Icons.account_balance})); }),
            ListTile(leading: const Icon(Icons.credit_card), title: const Text('Credit/Debit Card'), onTap: () { Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }
}
