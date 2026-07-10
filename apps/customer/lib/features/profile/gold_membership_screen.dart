import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class GoldMembershipScreen extends StatelessWidget {
  const GoldMembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.demoUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Gold Membership')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.gold, AppTheme.gold.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ZOMATO GOLD', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(user.isGoldMember ? 'Active until Aug 2026' : 'Unlock premium benefits', style: const TextStyle(color: Colors.white70)),
                if (user.isGoldMember) ...[
                  const SizedBox(height: 16),
                  const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 16), SizedBox(width: 8), Text('Free delivery on all orders', style: TextStyle(color: Colors.white))]),
                  const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 16), SizedBox(width: 8), Text('Extra 10% off at partner restaurants', style: TextStyle(color: Colors.white))]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Choose a Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ...MockData.goldPlans.map((p) => Card(
                child: ListTile(
                  title: Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [(p['benefits'] as List).map((b) => Text('• $b', style: const TextStyle(fontSize: 12))).toList()].expand((e) => e).toList()),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('₹${p['price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryRed)),
                      Text(p['duration'] as String, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subscribed to ${p['name']}'))),
                ),
              )),
        ],
      ),
    );
  }
}
