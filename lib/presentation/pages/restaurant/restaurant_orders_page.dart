import 'package:flutter/material.dart';

class RestaurantOrdersPage extends StatefulWidget {
  const RestaurantOrdersPage({super.key});

  @override
  State<RestaurantOrdersPage> createState() => _RestaurantOrdersPageState();
}

class _RestaurantOrdersPageState extends State<RestaurantOrdersPage> {
  String _selectedFilter = 'all';

  final List<RestaurantOrder> _orders = [
    RestaurantOrder(
      id: 'ORD-001',
      customerName: 'John Doe',
      items: ['Margherita Pizza x2', 'Caesar Salad x1'],
      total: 34.97,
      status: 'pending',
      orderTime: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    RestaurantOrder(
      id: 'ORD-002',
      customerName: 'Jane Smith',
      items: ['Pepperoni Pizza x1', 'Garlic Bread x2'],
      total: 28.97,
      status: 'preparing',
      orderTime: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    RestaurantOrder(
      id: 'ORD-003',
      customerName: 'Mike Johnson',
      items: ['Spaghetti Carbonara x1', 'Tiramisu x1'],
      total: 24.98,
      status: 'ready',
      orderTime: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    RestaurantOrder(
      id: 'ORD-004',
      customerName: 'Sarah Wilson',
      items: ['Quattro Formaggi x1', 'Lasagna x1'],
      total: 31.98,
      status: 'delivered',
      orderTime: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Preparing'),
            Tab(text: 'Ready'),
            Tab(text: 'Delivered'),
          ],
          onTap: (index) {
            setState(() {
              _selectedFilter = ['pending', 'preparing', 'ready', 'delivered'][index];
            });
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(_filteredOrders[index]);
        },
      ),
    );
  }

  List<RestaurantOrder> get _filteredOrders {
    if (_selectedFilter == 'all') {
      return _orders;
    }
    return _orders.where((order) => order.status == _selectedFilter).toList();
  }

  Widget _buildOrderCard(RestaurantOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.customerName,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatOrderTime(order.orderTime),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(item),
                )),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'preparing':
        color = Colors.blue;
        label = 'Preparing';
        break;
      case 'ready':
        color = Colors.green;
        label = 'Ready';
        break;
      case 'delivered':
        color = Colors.grey;
        label = 'Delivered';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatOrderTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildActionButtons(RestaurantOrder order) {
    switch (order.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _rejectOrder(order);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _acceptOrder(order);
                },
                child: const Text('Accept'),
              ),
            ),
          ],
        );
      case 'preparing':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _markAsReady(order);
            },
            child: const Text('Mark as Ready'),
          ),
        );
      case 'ready':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _callCustomer(order);
                },
                child: const Text('Call Customer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _assignDelivery(order);
                },
                child: const Text('Assign Delivery'),
              ),
            ),
          ],
        );
      case 'delivered':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _viewOrderDetails(order);
            },
            child: const Text('View Details'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _acceptOrder(RestaurantOrder order) {
    setState(() {
      order.status = 'preparing';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${order.id} accepted')),
    );
  }

  void _rejectOrder(RestaurantOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text('Are you sure you want to reject this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _orders.remove(order);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Order ${order.id} rejected')),
              );
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _markAsReady(RestaurantOrder order) {
    setState(() {
      order.status = 'ready';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${order.id} marked as ready')),
    );
  }

  void _callCustomer(RestaurantOrder order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${order.customerName}...')),
    );
  }

  void _assignDelivery(RestaurantOrder order) {
    setState(() {
      order.status = 'delivered';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delivery assigned for order ${order.id}')),
    );
  }

  void _viewOrderDetails(RestaurantOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order ${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.customerName}'),
            const SizedBox(height: 8),
            Text('Status: ${order.status}'),
            const SizedBox(height: 8),
            const Text('Items:'),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• $item'),
                )),
            const SizedBox(height: 8),
            Text('Total: \$${order.total.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class RestaurantOrder {
  final String id;
  final String customerName;
  final List<String> items;
  final double total;
  String status;
  final DateTime orderTime;

  RestaurantOrder({
    required this.id,
    required this.customerName,
    required this.items,
    required this.total,
    required this.status,
    required this.orderTime,
  });
}
