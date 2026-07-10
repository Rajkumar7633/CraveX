import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Earnings'),
          bottom: const TabBar(tabs: [Tab(text: 'Daily'), Tab(text: 'Weekly'), Tab(text: 'Monthly')]),
        ),
        body: TabBarView(
          children: [
            _earningsList(['Today', 'Yesterday'], [850, 720]),
            _earningsList(['This Week', 'Last Week'], [4200, 3800]),
            _earningsList(['This Month', 'Last Month'], [18500, 16200]),
          ],
        ),
      ),
    );
  }

  Widget _earningsList(List<String> labels, List<int> amounts) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppTheme.primaryRed,
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Earnings', style: TextStyle(color: Colors.white70)),
                Text('₹850', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(title: const Text('Delivery Fees'), trailing: Text('₹${600}')),
        ListTile(title: const Text('Tips'), trailing: Text('₹${120}')),
        ListTile(title: const Text('Peak Hour Bonus'), trailing: Text('₹${80}')),
        ListTile(title: const Text('Streak Bonus'), trailing: Text('₹${50}')),
        const Divider(),
        ...List.generate(labels.length, (i) => ListTile(
              title: Text(labels[i]),
              trailing: Text('₹${amounts[i]}', style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
        ElevatedButton(onPressed: () {}, child: const Text('Request Payout')),
      ],
    );
  }
}
