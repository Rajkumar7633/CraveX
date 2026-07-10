import 'package:core/core.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'New'), Tab(text: 'Preparing'), Tab(text: 'Ready'), Tab(text: 'History')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: List.generate(4, (_) => ListView(
              children: MockData.restaurantOrders.map((o) => Card(
                    margin: const EdgeInsets.all(8),
                    child: ExpansionTile(
                      title: Text('Order #${o.id.substring(o.id.length - 6)}'),
                      subtitle: Text(AppOrderStatus.labels[o.status] ?? o.status),
                      children: [
                        ...o.items.map((i) => ListTile(title: Text('${i.quantity}x ${i.name}'), trailing: Text('₹${i.lineTotal.toInt()}'))),
                        if (o.specialInstructions != null)
                          ListTile(title: Text('Note: ${o.specialInstructions}'), leading: const Icon(Icons.note)),
                        ListTile(
                          trailing: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.print),
                            label: const Text('Print KOT'),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
            )),
      ),
    );
  }
}
