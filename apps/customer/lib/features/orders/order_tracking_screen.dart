import 'dart:async';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _timer;
  late Order _order;
  int _statusIndex = 0;

  static const _progression = [
    AppOrderStatus.placed,
    AppOrderStatus.accepted,
    AppOrderStatus.preparing,
    AppOrderStatus.pickedUp,
    AppOrderStatus.onTheWay,
    AppOrderStatus.delivered,
  ];

  @override
  void initState() {
    super.initState();
    _order = OrderService().getOrder(widget.orderId) ??
        MockData.sampleOrder(AppOrderStatus.placed);
    _statusIndex = _progression.indexOf(_order.status).clamp(0, _progression.length - 1);
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_statusIndex < _progression.length - 1) {
        setState(() {
          _statusIndex++;
          final status = _progression[_statusIndex];
          OrderService().updateOrderStatus(widget.orderId, status);
          _order = _order.copyWith(
            status: status,
            riderName: _statusIndex >= 3 ? MockData.demoRider.name : null,
          );
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eta = _order.estimatedDeliveryTime.difference(DateTime.now()).inMinutes;
    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_order.status != AppOrderStatus.delivered)
            Card(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppTheme.primaryRed),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Arriving in ${eta > 0 ? eta : 5} mins',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(AppOrderStatus.labels[_order.status] ?? _order.status),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.grey),
                  Text('Live map tracking'),
                  Text('(Google Maps SDK integration)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OrderStatusTimeline(currentStatus: _order.status),
          const SizedBox(height: 24),
          if (_order.riderName != null) ...[
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.delivery_dining)),
                title: Text(_order.riderName!),
                subtitle: const Text('Delivery Partner'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.phone), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_order.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  ..._order.items.map((i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text('${i.quantity}x '),
                            Expanded(child: Text(i.name)),
                            Text('₹${i.lineTotal.toInt()}'),
                          ],
                        ),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('₹${_order.total.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_order.status == AppOrderStatus.delivered) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showRatingDialog(),
              icon: const Icon(Icons.star),
              label: const Text('Rate Order'),
            ),
            OutlinedButton(onPressed: () {}, child: const Text('Reorder')),
          ] else ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryRed),
              child: const Text('Cancel Order'),
            ),
          ],
        ],
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rate your order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Food Rating'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => IconButton(icon: const Icon(Icons.star, color: Colors.amber), onPressed: () {})),
            ),
            const Text('Delivery Rating'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => IconButton(icon: const Icon(Icons.star, color: Colors.amber), onPressed: () {})),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Submit')),
        ],
      ),
    );
  }
}
