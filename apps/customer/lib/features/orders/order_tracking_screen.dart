import 'dart:async';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
    final restaurant = MockData.restaurants.firstWhere(
      (r) => r.id == _order.restaurantId,
      orElse: () => MockData.restaurants.first,
    );
    final restLatLng = LatLng(restaurant.latitude, restaurant.longitude);
    final custLatLng = LatLng(_order.deliveryAddress.latitude, _order.deliveryAddress.longitude);

    LatLng? riderLatLng;
    if (_statusIndex >= 3) {
      double ratio = 0.0;
      if (_statusIndex == 3) ratio = 0.3;
      if (_statusIndex == 4) ratio = 0.75;
      if (_statusIndex == 5) ratio = 1.0;

      final lat = restLatLng.latitude + (custLatLng.latitude - restLatLng.latitude) * ratio;
      final lng = restLatLng.longitude + (custLatLng.longitude - restLatLng.longitude) * ratio;
      riderLatLng = LatLng(lat, lng);
    }

    final markers = [
      Marker(
        point: restLatLng,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
            border: Border.all(color: AppTheme.primaryRed, width: 2),
          ),
          child: const Icon(Icons.restaurant, color: AppTheme.primaryRed, size: 20),
        ),
      ),
      Marker(
        point: custLatLng,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 20),
        ),
      ),
      if (riderLatLng != null)
        Marker(
          point: riderLatLng,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: const Icon(Icons.delivery_dining, color: Colors.green, size: 20),
          ),
        ),
    ];

    final polylines = [
      Polyline(
        points: [restLatLng, custLatLng],
        color: AppTheme.primaryRed,
        strokeWidth: 4.0,
        borderStrokeWidth: 2.0,
        borderColor: Colors.white,
      ),
    ];

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
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: OsmMapWidget(
              markers: markers,
              polylines: polylines,
              zoom: 14.5,
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
