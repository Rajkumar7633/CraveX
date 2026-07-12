import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class DeliveryScreen extends StatefulWidget {
  final String orderId;
  const DeliveryScreen({super.key, required this.orderId});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  int _step = 0;
  final _steps = [
    'Navigate to Restaurant',
    'Arrived at Restaurant',
    'Pickup OTP Verification',
    'Navigate to Customer',
    'Arrived at Customer',
    'Delivery Complete',
  ];

  @override
  Widget build(BuildContext context) {
    final order = MockData.restaurantOrders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => MockData.restaurantOrders.first,
    );
    final restaurant = MockData.restaurants.firstWhere(
      (r) => r.id == order.restaurantId,
      orElse: () => MockData.restaurants.first,
    );
    final restLatLng = LatLng(restaurant.latitude, restaurant.longitude);
    final custLatLng = LatLng(order.deliveryAddress.latitude, order.deliveryAddress.longitude);

    LatLng riderLatLng;
    if (_step == 0) {
      riderLatLng = LatLng(restLatLng.latitude - 0.003, restLatLng.longitude - 0.002);
    } else if (_step == 1 || _step == 2) {
      riderLatLng = restLatLng;
    } else if (_step == 3) {
      riderLatLng = LatLng((restLatLng.latitude + custLatLng.latitude) / 2, (restLatLng.longitude + custLatLng.longitude) / 2);
    } else {
      riderLatLng = custLatLng;
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
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
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
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 20),
        ),
      ),
      Marker(
        point: riderLatLng,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
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
      appBar: AppBar(title: Text('Delivery #${widget.orderId.substring(widget.orderId.length - 6)}')),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / _steps.length, color: AppTheme.primaryRed),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                ..._steps.asMap().entries.map((e) {
                  final done = e.key < _step;
                  final active = e.key == _step;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: done ? Colors.green : active ? AppTheme.primaryRed : Colors.grey[300],
                      child: done ? const Icon(Icons.check, color: Colors.white, size: 18) : Text('${e.key + 1}'),
                    ),
                    title: Text(e.value, style: TextStyle(fontWeight: active ? FontWeight.bold : null)),
                  );
                }),
                if (_step == 2) ...[
                  const TextField(decoration: InputDecoration(labelText: 'Enter Pickup OTP', hintText: '1234')),
                ],
                if (_step == 5) ...[
                  const TextField(decoration: InputDecoration(labelText: 'Delivery OTP from Customer')),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Photo proof of delivery'),
                    trailing: ElevatedButton(onPressed: () {}, child: const Text('Capture')),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_step < _steps.length - 1)
                  ElevatedButton(
                    onPressed: () => setState(() => _step++),
                    child: Text(_stepButtonLabel()),
                  )
                else
                  ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Complete Delivery'),
                  ),
                if (_step > 0 && _step < _steps.length - 1)
                  TextButton(onPressed: () {}, child: const Text('Report Issue')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stepButtonLabel() {
    switch (_step) {
      case 0: return 'Start Navigation to Restaurant';
      case 1: return 'Confirm Arrival at Restaurant';
      case 2: return 'Confirm Pickup';
      case 3: return 'Start Navigation to Customer';
      case 4: return 'Confirm Arrival at Customer';
      default: return 'Next';
    }
  }
}
