import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = OrderService().orderHistory;
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No orders yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Order Now')),
                ],
              ),
            )
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final o = orders[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.restaurant)),
                    title: Text(o.restaurantName),
                    subtitle: Text('${o.items.length} items • ${AppOrderStatus.labels[o.status]}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${o.total.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextButton(onPressed: () => context.push('/order/${o.id}'), child: const Text('Track')),
                      ],
                    ),
                    onTap: () => context.push('/order/${o.id}'),
                  ),
                );
              },
            ),
    );
  }
}
