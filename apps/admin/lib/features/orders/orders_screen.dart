import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final orders = MockData.restaurantOrders;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Monitoring'),
        actions: [
          DropdownButton<String>(
            value: _filter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Orders')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'disputed', child: Text('Disputed')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
            onChanged: (v) => setState(() => _filter = v!),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 64, color: Colors.grey[400]),
                    Text('Live Order Map', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                    Text('${orders.length} active orders in Bangalore', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                const Text('Active Orders', style: TextStyle(fontWeight: FontWeight.bold)),
                ...orders.map((o) => Card(
                      child: ListTile(
                        title: Text('#${o.id.substring(o.id.length - 6)}'),
                        subtitle: Text('${o.restaurantName} • ₹${o.total.toInt()}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(AppOrderStatus.labels[o.status] ?? o.status, style: const TextStyle(fontSize: 11, color: AppTheme.primaryRed)),
                        ),
                        onTap: () => _showOrderDetail(o),
                      ),
                    )),
                const Divider(),
                const Text('Disputes', style: TextStyle(fontWeight: FontWeight.bold)),
                ...MockData.orderDisputes.map((d) => ListTile(
                      title: Text(d['orderId'] as String),
                      subtitle: Text(d['reason'] as String),
                      trailing: ElevatedButton(onPressed: () => _showRefundDialog(d['orderId'] as String), child: const Text('Review')),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetail(Order order) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(order.restaurantName),
            const Divider(),
            ...order.items.map((i) => Text('${i.quantity}x ${i.name} — ₹${i.lineTotal.toInt()}')),
            const Divider(),
            Text('Total: ₹${order.total.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Status: ${AppOrderStatus.labels[order.status]}'),
            Text('Rider: ${order.riderName ?? 'Not assigned'}'),
          ],
        ),
      ),
    );
  }

  void _showRefundDialog(String orderId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Refund — $orderId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Refund Amount')),
            const SizedBox(height: 8),
            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: 'Reason'),
              items: const [
                DropdownMenuItem(value: 'missing', child: Text('Missing item')),
                DropdownMenuItem(value: 'quality', child: Text('Quality issue')),
                DropdownMenuItem(value: 'late', child: Text('Late delivery')),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refund approved for $orderId'))); }, child: const Text('Approve Refund')),
        ],
      ),
    );
  }
}
