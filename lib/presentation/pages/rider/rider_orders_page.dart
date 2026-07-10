import 'package:flutter/material.dart';

class RiderOrdersPage extends StatefulWidget {
  const RiderOrdersPage({super.key});

  @override
  State<RiderOrdersPage> createState() => _RiderOrdersPageState();
}

class _RiderOrdersPageState extends State<RiderOrdersPage> {
  bool _isOnline = true;
  bool _isAvailable = true;

  final List<RiderOrder> _availableOrders = [
    RiderOrder(
      id: 'ORD-001',
      restaurantName: 'Italian Kitchen',
      restaurantAddress: '123 Main St',
      pickupAddress: '123 Main St',
      deliveryAddress: '456 Oak Ave',
      distance: 2.5,
      earnings: 5.99,
      items: ['Margherita Pizza x2', 'Caesar Salad x1'],
      estimatedTime: 15,
    ),
    RiderOrder(
      id: 'ORD-002',
      restaurantName: 'Spice Garden',
      restaurantAddress: '789 Elm St',
      pickupAddress: '789 Elm St',
      deliveryAddress: '321 Pine Rd',
      distance: 3.2,
      earnings: 7.49,
      items: ['Butter Chicken x1', 'Naan x2', 'Biryani x1'],
      estimatedTime: 20,
    ),
  ];

  final List<RiderOrder> _activeOrders = [
    RiderOrder(
      id: 'ORD-003',
      restaurantName: 'Tokyo Sushi',
      restaurantAddress: '555 Maple Dr',
      pickupAddress: '555 Maple Dr',
      deliveryAddress: '999 Cedar Ln',
      distance: 1.8,
      earnings: 6.49,
      items: ['Salmon Roll x4', 'Miso Soup x2'],
      estimatedTime: 10,
      status: 'picked_up',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Orders'),
        actions: [
          IconButton(
            icon: Icon(_isOnline ? Icons.toggle_on : Icons.toggle_off),
            onPressed: () {
              setState(() {
                _isOnline = !_isOnline;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Available Orders'),
                      Tab(text: 'Active Orders'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildAvailableOrders(),
                        _buildActiveOrders(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOnline
              ? [const Color(0xFFE23744), const Color(0xFFFF6B6B)]
              : [Colors.grey, Colors.grey],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isOnline ? 'You are Online' : 'You are Offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                activeColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isAvailable ? 'Accepting new orders' : 'Not accepting new orders',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableOrders() {
    if (!_isOnline || !_isAvailable) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.offline_pin,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Go online to receive orders',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_availableOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No orders available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay tuned for new orders',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(_availableOrders[index], true);
      },
    );
  }

  Widget _buildActiveOrders() {
    if (_activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No active orders',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(_activeOrders[index], false);
      },
    );
  }

  Widget _buildOrderCard(RiderOrder order, bool isAvailable) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        order.restaurantAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '\$${order.earnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Earnings',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildRouteInfo(order),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Order Items:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• $item',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                )),
            const SizedBox(height: 16),
            if (isAvailable)
              Row(
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
              )
            else
              _buildActiveOrderActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(RiderOrder order) {
    return Row(
      children: [
        Icon(Icons.restaurant, size: 20, color: Colors.orange[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pickup',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                order.pickupAddress,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Icon(Icons.location_on, size: 20, color: Colors.red[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                order.deliveryAddress,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveOrderActions(RiderOrder order) {
    switch (order.status) {
      case 'picked_up':
        return Column(
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${order.distance} km to delivery',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${order.estimatedTime} min',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _navigateToPickup(order);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _markAsDelivered(order);
                    },
                    child: const Text('Mark Delivered'),
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _acceptOrder(RiderOrder order) {
    setState(() {
      _availableOrders.remove(order);
      order.status = 'picked_up';
      _activeOrders.add(order);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${order.id} accepted')),
   ());
  }

  void _rejectOrder(RiderOrder order) {
    setState(() {
      _availableOrders.remove(order);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${order.id} rejected')),
    );
  }

  void _navigateToPickup(RiderOrder order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening navigation to ${order.deliveryAddress}')),
    );
  }

  void _markAsDelivered(RiderOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text('Have you delivered the order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _activeOrders.remove(order);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order ${order.id} delivered successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}

class RiderOrder {
  final String id;
  final String restaurantName;
  final String restaurantAddress;
  final String pickupAddress;
  final String deliveryAddress;
  final double distance;
  final double earnings;
  final List<String> items;
  final int estimatedTime;
  String status;

  RiderOrder({
    required this.id,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.distance,
    required this.earnings,
    required this.items,
    required this.estimatedTime,
    this.status = 'pending',
  });
}
