import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zomato_clone/core/router/app_router.dart';
import 'package:zomato_clone/core/services/realtime_service.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  String _currentStatus = 'confirmed';
  int _currentStep = 1;
  final OrderTrackingService _orderTrackingService = OrderTrackingService();
  bool _isRealtimeEnabled = true;
  final List<OrderStep> _steps = [
    OrderStep(
      title: 'Order Confirmed',
      subtitle: 'Your order has been received',
      icon: Icons.check_circle,
    ),
    OrderStep(
      title: 'Preparing',
      subtitle: 'Restaurant is preparing your food',
      icon: Icons.restaurant,
    ),
    OrderStep(
      title: 'Ready for Pickup',
      subtitle: 'Order is ready for delivery',
      icon: Icons.shopping_bag,
    ),
    OrderStep(
      title: 'On the Way',
      subtitle: 'Delivery partner is on the way',
      icon: Icons.delivery_dining,
    ),
    OrderStep(
      title: 'Delivered',
      subtitle: 'Order delivered successfully',
      icon: Icons.done_all,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (_isRealtimeEnabled) {
      _initializeRealtimeUpdates();
    } else {
      _simulateOrderProgress();
    }
  }

  void _initializeRealtimeUpdates() {
    _orderTrackingService.subscribeToOrderUpdates(widget.orderId, (data) {
      if (mounted) {
        final status = data['status'] as String?;
        if (status != null) {
          _updateOrderStatus(status);
        }
      }
    });
  }

  void _updateOrderStatus(String status) {
    setState(() {
      _currentStatus = status;
      switch (status) {
        case 'confirmed':
          _currentStep = 1;
          break;
        case 'preparing':
          _currentStep = 2;
          break;
        case 'ready':
          _currentStep = 3;
          break;
        case 'on_the_way':
          _currentStep = 4;
          break;
        case 'delivered':
          _currentStep = 5;
          break;
      }
    });
  }

  @override
  void dispose() {
    if (_isRealtimeEnabled) {
      _orderTrackingService.unsubscribeFromOrderUpdates(widget.orderId, (data) {});
    }
    super.dispose();
  }

  void _simulateOrderProgress() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentStatus = 'preparing';
          _currentStep = 2;
        });
      }
    });

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _currentStatus = 'ready';
          _currentStep = 3;
        });
      }
    });

    Future.delayed(const Duration(seconds: 9), () {
      if (mounted) {
        setState(() {
          _currentStatus = 'on_the_way';
          _currentStep = 4;
        });
      }
    });

    Future.delayed(const Duration(seconds: 12), () {
      if (mounted) {
        setState(() {
          _currentStatus = 'delivered';
          _currentStep = 5;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfo(),
            const SizedBox(height: 24),
            _buildTrackingTimeline(),
            const SizedBox(height: 24),
            _buildDeliveryPartnerInfo(),
            const SizedBox(height: 24),
            _buildOrderDetails(),
            const SizedBox(height: 24),
            _buildHelpSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Italian Kitchen',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Order #${widget.orderId}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated delivery: 30-35 mins',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_steps.length, (index) {
              final step = _steps[index];
              final isActive = index < _currentStep;
              final isCurrent = index == _currentStep - 1;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step.icon,
                          color: isActive ? Colors.white : Colors.grey,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              step.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive
                                    ? Colors.grey[700]
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (index < _steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 15, top: 8, bottom: 8),
                      child: Container(
                        height: 20,
                        width: 2,
                        color: isActive ? Colors.green : Colors.grey[300],
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryPartnerInfo() {
    if (_currentStep < 4) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Partner',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  child: Text('JD'),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'John Doe',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          SizedBox(width: 4),
                          Text('4.8'),
                          SizedBox(width: 8),
                          Text('(234 deliveries)'),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildOrderItem('Margherita Pizza', 2, 12.99),
            _buildOrderItem('Caesar Salad', 1, 8.99),
            const Divider(),
            _buildBillRow('Subtotal', '\$34.97'),
            _buildBillRow('Delivery Fee', '\$2.99'),
            _buildBillRow('Tax (8%)', '\$2.80'),
            const Divider(),
            _buildBillRow('Total', '\$40.76', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(String name, int quantity, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text('$name x$quantity'),
          ),
          Text('\$${(price * quantity).toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need Help?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              subtitle: const Text('24/7 customer support'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat with Us'),
              subtitle: const Text('Instant chat support'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel Order'),
              subtitle: const Text('Cancel if not yet prepared'),
              onTap: () {
                _showCancelDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              context.go(AppRouter.home);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

class OrderStep {
  final String title;
  final String subtitle;
  final IconData icon;

  OrderStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
