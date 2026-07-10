import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOpen = true;
  bool _busyMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meghana Foods'),
        actions: [
          Switch(
            value: _isOpen,
            onChanged: (v) => setState(() => _isOpen = v),
            activeThumbColor: Colors.green,
          ),
          Text(_isOpen ? 'Open' : 'Closed', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _drawer(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: const [
              StatCard(title: "Today's Orders", value: '24', icon: Icons.receipt),
              StatCard(title: 'Revenue', value: '₹12,450', icon: Icons.currency_rupee),
              StatCard(title: 'Avg Rating', value: '4.4', icon: Icons.star),
              StatCard(title: 'Pending', value: '3', icon: Icons.pending_actions),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Busy Mode'),
            subtitle: const Text('Pause new orders temporarily'),
            value: _busyMode,
            onChanged: (v) => setState(() => _busyMode = v),
          ),
          const Text('Live Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...MockData.restaurantOrders.map((o) => _orderCard(o)),
        ],
      ),
    );
  }

  Widget _orderCard(Order order) {
    Color statusColor = AppTheme.primaryRed;
    if (order.status == AppOrderStatus.preparing) statusColor = Colors.orange;
    if (order.status == AppOrderStatus.ready) statusColor = Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#${order.id.substring(order.id.length - 6)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(AppOrderStatus.labels[order.status] ?? order.status, style: TextStyle(color: statusColor, fontSize: 12)),
                ),
              ],
            ),
            Text('${order.items.length} items • ₹${order.total.toInt()}'),
            const SizedBox(height: 8),
            Row(
              children: [
                if (order.status == AppOrderStatus.placed) ...[
                  OutlinedButton(onPressed: () {}, child: const Text('Reject')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: () {}, child: const Text('Accept')),
                ] else if (order.status == AppOrderStatus.preparing) ...[
                  ElevatedButton(onPressed: () {}, child: const Text('Mark Ready')),
                ] else if (order.status == AppOrderStatus.ready) ...[
                  ElevatedButton(onPressed: () {}, child: const Text('Hand to Rider')),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Drawer _drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primaryRed),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Meghana Foods', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Partner Dashboard', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.dashboard), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.receipt_long), title: const Text('Orders'), onTap: () { Navigator.pop(context); context.go('/orders'); }),
          ListTile(leading: const Icon(Icons.restaurant_menu), title: const Text('Menu'), onTap: () { Navigator.pop(context); context.go('/menu'); }),
          ListTile(leading: const Icon(Icons.analytics), title: const Text('Analytics'), onTap: () { Navigator.pop(context); context.go('/analytics'); }),
          ListTile(leading: const Icon(Icons.star), title: const Text('Reviews'), onTap: () { Navigator.pop(context); context.go('/reviews'); }),
          ListTile(leading: const Icon(Icons.local_offer), title: const Text('Promotions'), onTap: () { Navigator.pop(context); context.go('/promotions'); }),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () { Navigator.pop(context); context.go('/settings'); }),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () => context.go('/login')),
        ],
      ),
    );
  }
}
