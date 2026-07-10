import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.primaryRed,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available Balance', style: TextStyle(color: Colors.white70)),
                  Text('₹${MockData.demoUser.walletBalance.toInt()}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryRed),
                    child: const Text('Add Money'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _txn('Order cashback', '+₹25', true),
          _txn('Referral bonus', '+₹50', true),
          _txn('Order payment', '-₹706', false),
          _txn('Gold membership', '-₹149', false),
        ],
      ),
    );
  }

  Widget _txn(String title, String amount, bool credit) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: credit ? Colors.green[50] : Colors.red[50],
        child: Icon(credit ? Icons.arrow_downward : Icons.arrow_upward,
            color: credit ? Colors.green : Colors.red, size: 18),
      ),
      title: Text(title),
      subtitle: Text('${DateTime.now().subtract(const Duration(days: 1)).toString().substring(0, 10)}'),
      trailing: Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: credit ? Colors.green : Colors.red)),
    );
  }
}
